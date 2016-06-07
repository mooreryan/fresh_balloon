#!/usr/bin/env ruby
require "parse_fasta"

VERSION = "v0.2.1"

if ARGV.count < 1
  warn "VERSION: #{VERSION}"
  warn "Add the file name to the header of the seqs and put all " +
       "seqs in one file"
  abort "USAGE:  annotate_seqs.rb seqs1.fa seqs2.fa ... > " +
        "one_big_file.fa"
end

def clean str
  str.gsub(/[^\p{Alnum}_]+/, "_").gsub(/_+/, "_")
end

ARGV.each do |fname|
  FastaFile.open(fname, "rt").each_record_fast do |head, seq|
    puts ">#{clean(fname)}_#{head}\n#{seq}"
  end
end
