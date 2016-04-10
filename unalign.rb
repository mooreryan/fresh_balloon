#!/usr/bin/env ruby

require "parse_fasta"

Signal.trap("PIPE", "EXIT")

FastaFile.open(ARGV.first).each_record do |head, seq|
  puts ">#{head}"
  puts seq.gsub(/[^a-zA-Z]/, "")
end
