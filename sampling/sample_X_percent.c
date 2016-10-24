/* to compile: gcc this_prog.c -lz */
#include <zlib.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

#include "kseq.h"

#define VERSION "0.1.0"

KSEQ_INIT(gzFile, gzread)

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

void print_record(kseq_t *seq) {
  if (seq->qual.l) {
    putchar('@');
  } else {
    putchar('>');
  }

  printf("%s", seq->name.s);

  if (seq->comment.l) {
    printf(" %s\n", seq->comment.s);
  } else {
    putchar('\n');
  }

  printf("%s\n", seq->seq.s);

  if (seq->qual.l) { printf("+\n%s\n", seq->qual.s); }
}

int main(int argc, char *argv[])
{
  /* seed rand */
  sranddev();


  int l;
  int num;
  int max;
  double percent = 0.0;
  unsigned long total = 0;
  unsigned long num_printed = 0;

  kseq_t *seq;
  gzFile fp;


    if (argc != 3) {
    fprintf(stderr, "Given fasta output seqs at least N bases long.\nVERSION: %s\nUsage: %s <percent to sample> <in.fa>\n", VERSION, argv[0]);

    return 1;
  }

    percent = strtod(argv[1], NULL);
    max = 100 / percent;

    fp = gzopen(argv[2], "r");

      if (!fp) {
    fprintf(stderr, "ERROR - could not open %s\n", argv[2]);

    return 2;
  }

  seq = kseq_init(fp);

  while ((l = kseq_read(seq)) >= 0) {
    ++total;
    if (total % 100000 == 0) {
      fprintf(stderr, "READING: %lu\r", total);
    }

    if (randnum(max) == 1) {
      ++num_printed;
      print_record(seq);
    }
  }

  kseq_destroy(seq);
  gzclose(fp);

  fprintf(stderr,
          "\n\nTotal reads: %lu, Num printed: %lu\n",
          total, num_printed);

  return 0;
}
