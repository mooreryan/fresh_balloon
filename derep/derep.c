/* to compile: gcc this_prog.c -lz */
#include <zlib.h>
#include <stdio.h>
#include <string.h>

#include "kseq.h"
#include "khash.h"

KSEQ_INIT(gzFile, gzread)
KHASH_SET_INIT_STR(str)

int main(int argc, char *argv[])
{
  gzFile fp;

  int l, i, absent;
  unsigned long total = 0;

  kseq_t *seq;
  khint_t key;
  khash_t(str) *hset;

  hset = kh_init(str);

  if (argc == 1) {
    fprintf(stderr, "Given fasta or fastq, output unique seqs in fasta format. New headers created.\nUsage: %s <in.f[aq]>\n", argv[0]);

    return 1;
  }

  fp = gzopen(argv[1], "r");
  seq = kseq_init(fp);

  while ((l = kseq_read(seq)) >= 0) {
    ++total;
    if (total % 100000 == 0) {
      fprintf(stderr, "READING: %lu\r", total);
    }

    key = kh_put(str, hset, seq->seq.s, &absent);
    if (absent) {
      kh_key(hset, key) = strdup(seq->seq.s);
    }
  }

  fprintf(stderr, "TOTAL SEQS:  %lu\n", total);
  fprintf(stderr, "UNIQUE SEQS: %d\n", kh_size(hset));

  i = 0;
  for (key = kh_begin(hset); key != kh_end(hset); ++key) {
    if (kh_exist(hset, key)) {
      printf(">seq_%d\n%s\n", ++i, kh_key(hset, key));
      free((char*)kh_key(hset, key));
    }
  }

  kseq_destroy(seq);
  kh_destroy(str, hset);
  gzclose(fp);

  return 0;
}
