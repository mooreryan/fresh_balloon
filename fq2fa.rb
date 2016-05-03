#!/usr/bin/env ruby

require "parse_fasta"

ARGV.each do |fname|
  FastqFile.open(fname).each_record_fast do |head, seq, desc, qual|
    puts ">#{head}\n#{seq}"
  end
end
