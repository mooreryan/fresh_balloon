#!/usr/bin/env ruby

# Copyright 2016 Ryan Moore
# Contact: moorer@udel.edu
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see
# <http://www.gnu.org/licenses/>.

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
