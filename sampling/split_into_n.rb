#!/usr/bin/env ruby
Signal.trap("PIPE", "EXIT")
require "parse_fasta"
require "abort_if"

include AbortIf

num_splits = ARGV.shift.to_i

ARGV.each do |fname|
  AbortIf.logger.info { "Splitting #{fname}" }

  files = num_splits.times.map { |n| File.open(fname + ".split_#{n}", "w") }

  num = 0
  counts = Array.new num_splits, 0
  ParseFasta::SeqFile.open(fname).each_record do |rec|
    idx = num % num_splits
    files[idx].puts rec
    counts[idx] += 1
    num += 1
  end

  files.each { |f| f.close }

  AbortIf.logger.info { "Reads in #{fname}: #{num}" }

  files.each_with_index do |f, idx|
    AbortIf.logger.info { "Reads in #{f.path}: #{counts[idx]}" }
  end
end
