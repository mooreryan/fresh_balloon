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
include AbortIf::Assert

inf = ARGV.first

rec_num = 0
prefixs = {}
still_paired = {}
warn "Checking #{inf} for paired reads"

ffout = "#{inf}.forward.fq"
rfout = "#{inf}.reverse.fq"

File.open(ffout, "w") do |ff|
  File.open(rfout, "w") do |rf|
    FastqFile.open(inf).each_record do |head, seq, desc, qual|
      $stderr.printf("Reading record: %d\r", rec_num) if (rec_num % 10_000).zero?
      rec_num += 1

      prefix = head.split(" ").first

      abort_if prefix.nil? || prefix.empty?,
               "Something wrong with #{head}"

      if prefixs.has_key? prefix
        abort_if still_paired.has_key?(prefix),
                 "Prefix #{prefix} was seen more than twice"

        o_head, o_seq, o_desc, o_qual = prefixs[prefix]
        still_paired[prefix] = rec_num

        if o_head.match("1:N:0") && head.match("2:N:0")
          ff.puts "@#{o_head}"
          ff.puts o_seq
          ff.puts "+#{o_desc}"
          ff.puts o_qual

          rf.puts "@#{head}"
          rf.puts seq
          rf.puts "+#{desc}"
          rf.puts qual
        elsif o_head.match("2:N:0") && head.match("1:N:0")
          rf.puts "@#{o_head}"
          rf.puts o_seq
          rf.puts "+#{o_desc}"
          rf.puts o_qual

          ff.puts "@#{head}"
          ff.puts seq
          ff.puts "+#{desc}"
          ff.puts qual
        else
          msg =
            "Couldn't determine orientation for #{head} and #{o_head}"
          AbortIf::logger.fatal { msg }
          abort
        end

      else
        prefixs[prefix] = [head, seq, desc, qual]
      end
    end
  end
end
$stderr.puts
warn "Wrote #{ffout}"
warn "Wrote #{rfout}"

sfout = "#{inf}.single.fq"
File.open(sfout, "w") do |f|
  (prefixs.keys - still_paired.keys).each do |unpaired_prefix|
    head, seq, desc, qual = prefixs[unpaired_prefix]

    f.puts "@#{head}"
    f.puts seq
    f.puts "+#{desc}"
    f.puts qual
  end
end
warn "Wrote #{sfout}"
