#!/usr/bin/env ruby
require "parse_fasta"

lengths = []
ARGV.each do |fname|
  warn "Processing: #{fname}"
  FastaFile.open(fname).each_record do |head, seq|
    lengths << seq.length
  end
end

max = lengths.max

num_digits = max.to_s.length

top = max.round(-(num_digits-1))

(0..top).step(1000).each do |len_cutoff|
  count = lengths.select { |len| len >= len_cutoff }.count

  puts [len_cutoff, count].join "\t"
end
