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

f1 = ARGV[0]
f2 = ARGV[1]

check_seq = ""
FastaFile.open(f1).each_record do |head, seq|
  check_seq = seq.gsub(".", "-")
end

FastaFile.open(f2).each_record do |head, seq|
  if seq.gsub(".", "-") == check_seq
    puts ">#{head}"
    puts seq
  end
end
