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

def count_seqs_fast fname
  if fname.match(/.gz$/)
    num_seqs = (`gunzip -c #{fname} | wc -l`.to_f / 4).round
  else
    num_seqs = (`wc -l #{fname}`.to_f / 4).round
  end

  num_seqs
end

require "parse_fasta"
require "abort_if"
require "trollop"
require "set"
require "fileutils"

include AbortIf
include AbortIf::Assert

opts = Trollop.options do
  version "v0.2.0"

  banner <<-EOS

  Assumes reads are in same order.

  Options:
  EOS

  opt(:num_reads, "Number of reads to take",
      type: :int, default: 100_000)
  opt(:num_samples, "Number of samples to take",
      type: :int, default: 10, short: "-s")
  opt(:fastq, "Fastq reads", type: :string)
  opt(:basename, "Basename for output", type: :string,
      default: "subsets")
  opt(:outdir, "Output directory", type: :string, default: ".")
end

FileUtils.mkdir_p opts[:outdir]

fastq_seq_num = count_seqs_fast opts[:fastq]
AbortIf.logger.info { "#{opts[:fastq]}: #{fastq_seq_num} seqs" }

num_seqs = fastq_seq_num

arr = (1..num_seqs).to_a
reads_to_take =
  opts[:num_samples].times.map do
  Set.new(arr.shuffle.take(opts[:num_reads]))
end

begin
  outfiles = []
  opts[:num_samples].times do |n|
    fname = File.join opts[:outdir], "#{opts[:basename]}.subset_#{n}.fq"
    outfiles << File.open(fname, "w")
  end

  AbortIf.logger.info { "Processing #{opts[:fastq]}" }
  rec = 0
  FastqFile.open(opts[:fastq]).each_record_fast do |head, seq, desc, qual|
    $stderr.printf("Record: %d\r", rec) if (rec % 10_000).zero?
    rec += 1

    reads_to_take.each_with_index do |rec_numbers, idx|
      if rec_numbers.include? rec
        outfiles[idx].printf "@%s\n%s\n+%s\n%s\n", head, seq, desc, qual
      end
    end
  end
  $stderr.puts
ensure
  outfiles.each { |fname| fname.close }
end
