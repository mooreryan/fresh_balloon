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

# monkey patch parse_fasta for speeeeed
class FastqFile
  def each_record
    count = 0
    header = ''
    sequence = ''
    description = ''
    quality = ''

    begin
      f = Zlib::GzipReader.open(self)
    rescue Zlib::GzipFile::Error => e
      f = self
    end

    f.each_line do |line|
      line.chomp!

      case count % 4
      when 0
        header = line[1..-1] # line.sub(/^@/, '')
      when 1
        sequence = line # Sequence.new(line)
      when 2
        description = line[1..-1] # line.sub(/^\+/, '')
      when 3
        quality = line # Quality.new(line)
        yield(header, sequence, description, quality)
      end

      count += 1
    end

    f.close if f.instance_of?(Zlib::GzipReader)
    return f
  end
end


include AbortIf
include AbortIf::Assert

# inf = ARGV.first
inf = "test_files/ami.test.fq.gz"

rec_num = 0
prefixs = {}
still_paired = Set.new
warn "Checking #{inf} for paired reads"

ffout = "#{inf}.forward.fq"
rfout = "#{inf}.reverse.fq"

File.open(ffout, "w") do |ff|
  File.open(rfout, "w") do |rf|
    FastqFile.open(inf).each_record do |head, seq, desc, qual|
      $stderr.printf("Reading record: %d\r", rec_num) if (rec_num % 10_000).zero?
      rec_num += 1

      current_prefix = head.split(" ")[0]

      abort_if current_prefix.nil? || current_prefix.empty?,
               "Something wrong with #{head}"

      if prefixs.has_key? current_prefix
        abort_if still_paired.include?(current_prefix),
                 "Prefix #{current_prefix} was seen more than twice"

        o_head, o_seq, o_desc, o_qual = prefixs[current_prefix]
        still_paired << current_prefix

        if o_head.include?("1:N:0") && head.include?("2:N:0")
          ff.puts "@#{o_head}\n#{o_seq}\n+#{o_desc}\n#{o_qual}"

          rf.puts "@#{head}\n#{seq}\n+#{desc}\n#{qual}"
        elsif o_head.include?("2:N:0") && head.include?("1:N:0")
          rf.puts "@#{o_head}\n#{o_seq}\n+#{o_desc}\n#{o_qual}"

          ff.puts "@#{head}\n#{seq}\n+#{desc}\n#{qual}"
        else
          msg =
            "Couldn't determine orientation for #{head} and #{o_head}"
          AbortIf::logger.fatal { msg }
          abort
        end

      else
        prefixs[current_prefix] = [head, seq, desc, qual]
      end
    end
  end
end
$stderr.puts
warn "Wrote #{ffout}"
warn "Wrote #{rfout}"

sfout = "#{inf}.single.fq"
File.open(sfout, "w") do |f|
  (prefixs.keys - still_paired.to_a).each do |unpaired_prefix|
    head, seq, desc, qual = prefixs[unpaired_prefix]

    f.puts "@#{head}\n#{seq}\n+#{desc}\n#{qual}"
  end
end
warn "Wrote #{sfout}"
