/* to compile: gcc this_prog.c -lz */
#include <zlib.h>
#include <stdio.h>
#include <string.h>

#include "kseq.h"

#define VERSION "0.1.0"

KSEQ_INIT(gzFile, gzread)

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
  int l;
  unsigned long total = 0;
  unsigned long min_l = 0;
  unsigned long max_l = 0;

  kseq_t *seq;
  gzFile fp;

  if (argc != 4) {
    fprintf(stderr, "Given fasta output seqs with min_len <= seq_len <= max_len long.\nVERSION: %s\nUsage: %s <min_len> <max_len> <in.fa>\n", VERSION, argv[0]);

    return 1;
  }

  if (argv[1][0] == '-') {
    fprintf(stderr, "ERROR -- min length must be > 0, got %s\n", argv[1]);

    return 1;
  }

  min_l = strtoul(argv[1], NULL, 10);

  if (argv[2][0] == '-') {
    fprintf(stderr, "ERROR -- max length must be > 0, got %s\n", argv[1]);

    return 1;
  }

  max_l = strtoul(argv[2], NULL, 10);

  if (min_l > max_l) {
    fprintf(stderr, "ERROR -- min_l > max_l\n");

    return 1;
  }

  fp = gzopen(argv[3], "r");

  if (!fp) {
    fprintf(stderr, "ERROR - could not open %s\n", argv[3]);

    return 2;
  }

  seq = kseq_init(fp);

  while ((l = kseq_read(seq)) >= 0) {
    ++total;
    if (total % 100000 == 0) {
      fprintf(stderr, "READING: %lu\r", total);
    }

    if (min_l <= seq->seq.l && seq->seq.l <= max_l) {
      print_record(seq);
    }
  }

  kseq_destroy(seq);
  gzclose(fp);

  return 0;
}
