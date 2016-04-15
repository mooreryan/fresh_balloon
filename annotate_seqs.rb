#!/usr/bin/env ruby
require "parse_fasta"

def clean str
  str.gsub(/[^\p{Alnum}_]+/, "_").gsub(/_+/, "_")
end

ARGV.each do |fname|
  FastaFile.open(fname, "rt").each_record do |head, seq|
    puts "#{clean(fname)}_#{head}"
    puts seq
  end
end
