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

require "./lib/crystal/methods"

abort "USAGE: length_hist <fname>" if ARGV.size != 1

fname = ARGV[0]
lengths = [] of Int32
n = 0

if !File.exists?(fname)
  abort "ERROR: File #{fname} does not exist"
end
STDERR.puts "LOG -- reading #{fname}"

each_record(fname) do |head, seq|
  n += 1
  STDERR.printf("LOG -- processing: %d\n", n) if (n % 100000) == 0
  lengths << seq.size
end

STDERR.puts

max = lengths.max

num_digits = max.to_s.size

top = max.round(-(num_digits-1))

(0..top).step(1000).each do |len_cutoff|
  count = lengths.select { |len| len >= len_cutoff }.size

  puts [len_cutoff, count].join "\t"
end
