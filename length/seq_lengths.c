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

  kseq_t *seq;
  gzFile fp;

  if (argc == 1) {
    fprintf(stderr, "VERSION: %s\nUsage: %s f1.fa f2.fq ... > seq_lengths.tsv\n",
            VERSION,
            argv[0]);

    return 1;
  }

  for (i = 1; i < argc; ++i) {
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
      printf("%s\t%lu\n", seq->name.s, seq->seq.l);
    }

    kseq_destroy(seq);
    gzclose(fp);
  }

  return 0;
}
