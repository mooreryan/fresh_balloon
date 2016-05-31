/* to compile: gcc this_prog.c -lz */
#include <zlib.h>
#include <stdio.h>
#include <string.h>

#include "kseq.h"

#define VERSION "0.1.0"

KSEQ_INIT(gzFile, gzread)

int main(int argc, char *argv[])
{
  int i;
  long l;

  unsigned long total_bases   = 0;
  unsigned long total_contigs = 0;

  unsigned long num_bases   = 0;
  unsigned long num_contigs = 0;

  kseq_t *seq;
  gzFile fp;

  if (argc == 1) {
    fprintf(stderr, "VERSION: %s\nUsage: %s f1.fa f2.fq ...\n",
            VERSION,
            argv[0]);

    return 1;
  }

  for (i = 1; i < argc; ++i) {
    num_bases   = 0;
    num_contigs = 0;

    fp = gzopen(argv[i], "r");

    if (!fp) {
      fprintf(stderr, "ERROR - could not open %s\n", argv[1]);

      return 2;
    }

    seq = kseq_init(fp);

    if (!seq) {
      fprintf(stderr, "ERROR - could init seq\n");

      return 3;
    }

    while ((l = kseq_read(seq)) >= 0) {
      ++num_contigs;
      num_bases += seq->seq.l;
    }

    total_bases += num_bases;
    total_contigs += num_contigs;

    fprintf(stderr,
            "%s\t%lu\t%lu\t%.2f\n",
            argv[i],
            num_bases,
            num_contigs,
            num_bases / (double) num_contigs);

    kseq_destroy(seq);
    gzclose(fp);

  }

  printf("Total\t%lu\t%lu\t%.2f\n",
         total_bases,
         total_contigs,
         total_bases / (double) total_contigs);

  return 0;
}
