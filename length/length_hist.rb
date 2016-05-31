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

lengths = []
ARGV.each do |fname|
  warn "Processing: #{fname}"
  n = 0
  SeqFile.open(fname).each_record_fast do |head, seq|
    n += 1
    $stderr.printf("LOG -- processing: %d\r", n) if (n % 10_000).zero?
    lengths << seq.length
  end
end
$stderr.puts

max = lengths.max

num_digits = max.to_s.length

top = max.round(-(num_digits-1))

(0..top).step(1000).each do |len_cutoff|
  count = lengths.select { |len| len >= len_cutoff }.count

  puts [len_cutoff, count].join "\t"
end
