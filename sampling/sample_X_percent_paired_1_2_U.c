/* to compile: gcc this_prog.c -lz */
#include <zlib.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/time.h>

#include "kseq.h"

#define VERSION "0.1.0"

KSEQ_INIT(gzFile, gzread)

typedef struct outf_t {
  char* fname;
  FILE* fp;
} outf_t;

outf_t* outf_init(char* fname)
{
  char* tmp = malloc(sizeof(char) * (strlen(fname) + 1));
  strcpy(tmp, fname);

  outf_t* outf = malloc(sizeof(outf_t));
  outf->fname = tmp;
  outf->fp = fopen(outf->fname, "w");

  if (!outf->fp) {
    fprintf(stderr,
            "ERROR -- Couldn't open %s for writing\n",
            outf->fname);

    free(tmp);
    free(outf);

    exit(3);
  }

  return outf;
}

void outf_destroy(outf_t* outf)
{
  free(outf->fname);
  /* free(outf->fp); */
  free(outf);
}

/* from http://www.c-faq.com/lib/randrange.kirby.html */
int randnum(int range)
{
  int divisor = RAND_MAX / range;
  int threshold = RAND_MAX - RAND_MAX % range;
  int randval;

  while ((randval = rand()) >= threshold)
    ;

  return randval / divisor;
}

void print_record(kseq_t *seq, FILE *outf) {
  if (seq->qual.l) {
    fprintf(outf, "@");
  } else {
    fprintf(outf, ">");
  }

  fprintf(outf, "%s", seq->name.s);

  if (seq->comment.l) {
    fprintf(outf, " %s\n", seq->comment.s);
  } else {
    fprintf(outf, "\n");
  }

  fprintf(outf, "%s\n", seq->seq.s);

  if (seq->qual.l) { fprintf(outf, "+\n%s\n", seq->qual.s); }
}

int main(int argc, char *argv[])
{
  /* seed rand */
  struct timeval t1;
  gettimeofday(&t1, NULL);
  srand(t1.tv_usec * t1.tv_sec);

  /* throw out the first couple of outputs */
  for (int i = 0; i < 10; ++i) {
    randnum(10);
  }

  int i = 0;
  int l1;
  int l2;
  int max;
  double percent = 0.0;
  long num_samples = 0;
  unsigned long total = 0;

  kseq_t *seq1;
  kseq_t *seq2;
  kseq_t *seqU;
  gzFile fp1;
  gzFile fp2;
  gzFile fpU;

  char fname_buf[1000];

  if (argc != 8) {
    fprintf(stderr,
            "VERSION: %s\nUsage: %s <1: percent to sample> "
            "<2: number of samples> <3: outdir> "
            "<4: basename for outfiles> "
            "<5: in.1.f{a,q}> <6: in.2.f{a,q}> <7: in.U.f{a,q}>\n",
            VERSION,
            argv[0]);

    return 1;
  }

  percent = strtod(argv[1], NULL);
  num_samples = strtol(argv[2], NULL, 10);

  outf_t *outfiles1[num_samples];
  outf_t *outfiles2[num_samples];
  outf_t *outfilesU[num_samples];
  for (i = 0; i < num_samples; ++i) {
    sprintf(fname_buf,
            "%s/%s.sample_%d.1.fq",
            argv[3],
            argv[4],
            i);
    outfiles1[i] = outf_init(fname_buf);

    sprintf(fname_buf,
            "%s/%s.sample_%d.2.fq",
            argv[3],
            argv[4],
            i);
    outfiles2[i] = outf_init(fname_buf);

    sprintf(fname_buf,
            "%s/%s.sample_%d.U.fq",
            argv[3],
            argv[4],
            i);
    outfilesU[i] = outf_init(fname_buf);
  }


  max = 100 / percent;

  fp1 = gzopen(argv[5], "r");
  fp2 = gzopen(argv[6], "r");
  fpU = gzopen(argv[7], "r");

  if (!fp1) {
    fprintf(stderr,
            "ERROR - could not open %s\n",
            argv[5]);

    return 2;
  }

  if (!fp2) {
    fprintf(stderr,
            "ERROR - could not open %s\n",
            argv[6]);

    return 2;
  }

  if (!fpU) {
    fprintf(stderr,
            "ERROR - could not open %s\n",
            argv[7]);

    return 2;
  }

  seq1 = kseq_init(fp1);
  seq2 = kseq_init(fp2);
  seqU = kseq_init(fpU);

  while ((l1 = kseq_read(seq1)) >= 0) {
    /* TODO: might be faster to read all of one, mark the records
       taken and then read all of the second? */
    l2 = kseq_read(seq2);
    if (l2 < 0) {
      fprintf(stderr,
              "ERROR -- not enough reads in reverse file %s\n",
              argv[3]);
    }

    ++total;
    if (total % 100000 == 0) {
      fprintf(stderr,
              "INFO -- reading paired files: %lu\r",
              total);
    }

    for (i = 0; i < num_samples; ++i) {
      if (randnum(max) == 1) {
        print_record(seq1, outfiles1[i]->fp);
        print_record(seq2, outfiles2[i]->fp);
      }
    }
  }

  total = 0;
  while ((l1 = kseq_read(seqU)) >= 0) {
    ++total;
    if (total % 100000 == 0) {
      fprintf(stderr,
              "INFO -- reading unpaired file: %lu\r",
              total);
    }

    for (i = 0; i < num_samples; ++i) {
      if (randnum(max) == 1) {
        print_record(seqU, outfilesU[i]->fp);
      }
    }
  }

  kseq_destroy(seq1);
  kseq_destroy(seq2);
  kseq_destroy(seqU);

  gzclose(fp1);
  gzclose(fp2);
  gzclose(fpU);

  for (i = 0; i < num_samples; ++i) {
    outf_destroy(outfiles1[i]);
    outf_destroy(outfiles2[i]);
    outf_destroy(outfilesU[i]);
  }

  return 0;
}
