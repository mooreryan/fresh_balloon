/* to compile: gcc this_prog.c -lz */
#include <zlib.h>
#include <stdio.h>
#include "kseq.h"
KSEQ_INIT(gzFile, gzread)

int main(int argc, char *argv[])
{
  gzFile fp;
  kseq_t *seq;
  int l;
  if (argc != 2) {
    fprintf(stderr, "Usage: %s <in.fasta>\n", argv[0]);

    return 1;
  }

  fp = gzopen(argv[1], "r");
  seq = kseq_init(fp);

  while ((l = kseq_read(seq)) >= 0) {
    printf("%s %s\t%zu\n", seq->name.s, seq->comment.s, seq->seq.l);
  }

  kseq_destroy(seq);
  gzclose(fp);

  return 0;
}
