CC = gcc
CFLAGS = -Wall -g -lz

derep: derep.c kseq.h khash.h
	$(CC) $(CFLAGS) -o derep derep.c

clean:
	rm -r derep derep.dSYM

# all: derep.o bstrlib.o
# 	$(CC) $(CFLAGS) -o derep derep.o bstrlib.o

# derep.o: derep.c kseq.h bstrlib.h
# 	$(CC) $(CFLAGS) -c derep.c

# clean:
# 	rm derep derep.o bstrlib.o
