#!/usr/bin/env ruby

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

require "parallel"

VERSION = 'v0.1.0'

if ARGV.empty?
  warn "VERSION: #{VERSION}"
  abort "USAGE: countfq_parallel.rb threads r1.fq r2.fq r3.fq ..."
end

threads = ARGV.shift.to_i

total = 0
Parallel.each(ARGV, in_processes: threads) do |fname|
  if fname.match(/.gz$/)
    num_seqs = (`gunzip -c #{fname} | wc -l`.to_f / 4).round
  else
    num_seqs = (`wc -l #{fname}`.to_f / 4).round
  end

  puts
  puts [fname, num_seqs].join "\t"

  total += num_seqs
end

puts
puts
puts "Total seqs: #{total}"
