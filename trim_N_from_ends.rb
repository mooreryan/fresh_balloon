#!/usr/bin/env ruby

require "parse_fasta"
require "abort_if"

include AbortIf

fname = ARGV.first

outf = fname + ".trimmed_N_from_ends.fq"
num_trimmed = 0
rec = 0
File.open(outf, "w") do |f|
  FastqFile.open(fname).each_record do |head, seq, desc, qual|
    rec += 1
    $stderr.printf "Read: %d\r", rec if (rec % 10000).zero?

    start = -1
    stop = 0

    seq.each_char.with_index do |c, i|
      if c == "N" || c == "n"
      # pass
      else
        start = i
        break
      end
    end

    seq.reverse.each_char.with_index do |c, i|
      if c == "N" || c == "n"
      # pass
      else
        stop = i + 1
        break
      end
    end

    abort_if start == -1 || stop == 0, "Something went wrong: #{head}"
    num_trimmed += 1 if start > 0 || stop > 1

    f.puts "@#{head}"
    f.puts seq[start..-stop]
    f.puts "+#{desc}"
    f.puts qual[start..-stop]
  end
end
$stderr.puts
$stderr.puts "For #{fname}...output file: #{outf}"
$stderr.puts "Number trimed: #{num_trimmed}"
$stderr.puts "Total reads:   #{rec}"
$stderr.puts
