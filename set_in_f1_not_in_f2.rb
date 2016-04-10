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

require "set"

def file_to_set fname
  s = Set.new

  File.open(fname).each_line { |line| s << line.chomp }

  s
end

f1 = ARGV[0]
f2 = ARGV[1]

s1 = file_to_set f1
s2 = file_to_set f2

s1.each do |elem1|
  if s2.none? { |elem2| elem1.match(elem2) || elem2.match(elem1) }
    puts elem1
  end
end
