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
require "set"

include AbortIf
include AbortIf::Assert

VERSION = "0.1.0"

if ARGV[0] == "-v" || ARGV[0] == "--version"
  warn "VERSION -- #{VERSION}"
  exit
end

rev_num = ARGV[0]
inf = ARGV[1]

abort_unless ARGV.count == 2,
             "USAGE -- am_i_still_paired.rb reverse_read_specifier reads.fastq"

abort_unless rev_num == "2" || rev_num == "3",
             "the first arg must be either 2 or 3"

rec_num = 0
prefixs = {}
still_paired = Set.new
warn "Checking #{inf} for paired reads"

ffout = "#{inf}.forward.fa"
rfout = "#{inf}.reverse.fa"

File.open(ffout, "w") do |ff|
  File.open(rfout, "w") do |rf|
    FastaFile.open(inf).each_record_fast do |head, seq|
      $stderr.printf("Reading record: %d\r", rec_num) if (rec_num % 10_000).zero?
      rec_num += 1

      current_prefix = head.split(" ")[0]

      abort_if current_prefix.nil? || current_prefix.empty?,
               "Something wrong with #{head}"

      if prefixs.has_key? current_prefix
        abort_if still_paired.include?(current_prefix),
                 "Prefix #{current_prefix} was seen more than twice"

        o_head, o_seq = prefixs[current_prefix]
        still_paired << current_prefix

        if o_head.include?("1:N:0") && head.include?("#{rev_num}:N:0")
          ff.puts ">#{o_head}\n#{o_seq}"

          rf.puts ">#{head}\n#{seq}"
        elsif o_head.include?("#{rev_num}:N:0") && head.include?("1:N:0")
          rf.puts ">#{o_head}\n#{o_seq}"

          ff.puts ">#{head}\n#{seq}"
        else
          msg =
            "Couldn't determine orientation for #{head} and #{o_head}"
          AbortIf::logger.fatal { msg }
          abort
        end

      else
        prefixs[current_prefix] = [head, seq]
      end
    end
  end
end
$stderr.puts
warn "Wrote #{ffout}"
warn "Wrote #{rfout}"

sfout = "#{inf}.single.fa"
File.open(sfout, "w") do |f|
  prefixs.each_with_index do |(prefix, info), idx|
    unless still_paired.include? prefix
      $stderr.printf("Processing unpaired: %d\r", idx) if (idx % 10_000).zero?
      head, seq = info

      f.puts ">#{head}\n#{seq}"
    end
  end
end
$stderr.puts
warn "Wrote #{sfout}"
