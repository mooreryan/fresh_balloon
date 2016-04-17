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

def abort_if(test, msg="Fatal error")
  if test
    abort "ERROR -- #{msg}"
  end
end

def eputs(msg="")
  STDERR.puts msg
end

require "bio"
require "set"

abort_if ARGV.empty?, "Need to provide an infile"

inf = ARGV.first

rec_num = 0
prefixs = {} of String => Array(String)
still_paired = Set(String).new
eputs "Checking #{inf} for paired reads"

dir  = File.dirname(inf)
base = File.basename(inf, File.extname(inf))
outbase = File.join dir, base

ffout = "#{outbase}.forward.fq"
rfout = "#{outbase}.reverse.fq"
sfout = "#{outbase}.single.fq"

File.open(ffout, "w") do |ff|
  File.open(rfout, "w") do |rf|
    Bio::FastqFile.open(inf).each_record do |head, seq, desc, qual|
      rec_num += 1
      eputs("Reading record: #{rec_num}") if (rec_num % 100_000) == 0

      current_prefix = head.split(" ")[0]

      abort_if current_prefix.nil? || current_prefix.empty?,
               "Something wrong with #{head}"

      if prefixs.has_key? current_prefix
        abort_if still_paired.includes?(current_prefix),
                 "Prefix #{current_prefix} was seen more than twice"

        o_head, o_seq, o_desc, o_qual = prefixs[current_prefix]
        still_paired << current_prefix

        if o_head.includes?("1:N:0") && head.includes?("2:N:0")
          ff.puts "@#{o_head}\n#{o_seq}\n+#{o_desc}\n#{o_qual}"

          rf.puts "@#{head}\n#{seq}\n+#{desc}\n#{qual}"
        elsif o_head.includes?("2:N:0") && head.includes?("1:N:0")
          rf.puts "@#{o_head}\n#{o_seq}\n+#{o_desc}\n#{o_qual}"

          ff.puts "@#{head}\n#{seq}\n+#{desc}\n#{qual}"
        else
          msg =
            "Couldn't determine orientation for #{head} and #{o_head}"
          abort_if true, msg
        end
      else
        prefixs[current_prefix] = [head, seq, desc, qual]
      end
    end
  end
end
eputs
eputs "Wrote #{ffout}"
eputs "Wrote #{rfout}"

File.open(sfout, "w") do |f|
  idx = 0
  prefixs.each do |prefix, info|
    unless still_paired.includes? prefix
      idx += 1
      eputs("Processing unpaired: #{idx}") if (idx % 100_000) == 0
      head, seq, desc, qual = info

      f.puts "@#{head}\n#{seq}\n+#{desc}\n#{qual}"
    end
  end
end
eputs
eputs "Wrote #{sfout}"
