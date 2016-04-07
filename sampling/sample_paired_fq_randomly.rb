#!/usr/bin/env ruby

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
  banner <<-EOS

  Assumes reads are in same order.

  Options:
  EOS

  opt(:num_reads, "Number of reads to take",
      type: :int, default: 100_000)
  opt(:num_samples, "Number of samples to take",
      type: :int, default: 10, short: "-s")
  opt(:forward, "Forward reads", type: :string)
  opt(:reverse, "Reverse reads", type: :string)
  opt(:basename, "Basename for output", type: :string,
      default: "subsets")
  opt(:outdir, "Output directory", type: :string, default: ".")
end

FileUtils.mkdir_p opts[:outdir]

forward_seq_num = count_seqs_fast opts[:forward]
AbortIf.logger.info { "#{opts[:forward]}: #{forward_seq_num} seqs" }

reverse_seq_num = count_seqs_fast opts[:reverse]
AbortIf.logger.info { "#{opts[:reverse]}: #{reverse_seq_num} seqs" }

abort_unless forward_seq_num == reverse_seq_num,
             "Seq number mistmatched"

num_seqs = forward_seq_num

arr = (1..num_seqs).to_a
reads_to_take =
  opts[:num_samples].times.map do
  Set.new(arr.shuffle.take(opts[:num_reads]))
end

begin
  outfiles = { forward: [], reverse: [] }
  opts[:num_samples].times do |n|
    ffname = File.join opts[:outdir], "#{opts[:basename]}.subset_#{n}.1.fq"
    rfname = File.join opts[:outdir], "#{opts[:basename]}.subset_#{n}.2.fq"
    outfiles[:forward] << File.open(ffname, "w")
    outfiles[:reverse] << File.open(rfname, "w")
  end

  AbortIf.logger.info { "Processing #{opts[:forward]}" }
  rec = 0
  FastqFile.open(opts[:forward]).each_record do |head, seq, desc, qual|
    $stderr.printf("Record: %d\r", rec) if (rec % 10_000).zero?
    rec += 1

    reads_to_take.each_with_index do |rec_numbers, idx|
      if rec_numbers.include? rec
        outfiles[:forward][idx].printf "@%s\n%s\n+%s\n%s\n", head, seq, desc, qual
      end
    end
  end
  $stderr.puts

  AbortIf.logger.info { "Processing #{opts[:forward]}" }
  rec = 0
  FastqFile.open(opts[:reverse]).each_record do |head, seq, desc, qual|
    $stderr.printf("Record: %d\r", rec) if (rec % 10_000).zero?
    rec += 1

    reads_to_take.each_with_index do |rec_numbers, idx|
      if rec_numbers.include? rec
        outfiles[:reverse][idx].printf "@%s\n%s\n+%s\n%s\n", head, seq, desc, qual
      end
    end
  end
  $stderr.puts

ensure
  outfiles.each { |_, fnames| fnames.each { |fname| fname.close } }
end
