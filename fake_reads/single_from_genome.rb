#!/usr/bin/env ruby

Signal.trap("PIPE", "EXIT")

require "parse_fasta"
require "abort_if"

include AbortIf

abort_if ARGV.count < 1 || ARGV.count > 3,
         "USAGE: ruby #{__FILE__} genome.fasta <num_reads=100> " +
         "<read_length=250>\n" +
         "I only sample the first seq in a fasta file!"

fname = ARGV[0]

if ARGV[1]
  num_reads = ARGV[1].to_i
else
  num_reads = 100
end

if ARGV[2]
  read_len = ARGV[2].to_i
else
  read_len = 250
end

ParseFasta::SeqFile.open(ARGV.first).each_record do |rec|
  orig_len = rec.seq.length

  start_idxs = (0 .. (orig_len-read_len)).to_a

  num_reads.times do |read_num|
    start = start_idxs.sample
    read = rec.seq[start, read_len]

    puts ">read_#{read_num+1} zero_based_start_pos_#{start} " +
         "len_#{read_len} from #{rec.header}\n#{read}"
  end

  break
end

AbortIf.logger.info { "DONE! Wrote #{num_reads} reads of length " +
                      "#{read_len} from #{fname}" }
