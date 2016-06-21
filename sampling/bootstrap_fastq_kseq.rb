#!/usr/bin/env ruby

require "trollop"
require "bio/kseq"
require "fileutils"

Signal.trap("PIPE", "EXIT")

opts = Trollop.options do
  version "Version: 0.1.0"
  banner <<-EOS

  Outputs monte carlo bootstraps of the input fastq file.

  Note: reads whole file into memory

  Options:
  EOS

  opt(:fastq, "Input FASTQ", type: :string)
  opt(:num, "Number of bootstraps", type: :integer, default: 3)
  opt(:basename, "Basename of output files", type: :string,
      default: "sample")
  opt(:outdir, "Output directory", type: :string, default: ".")
end

STDERR.puts "Reading records"
records = []
n = 0

kseq = Bio::Kseq.new(opts[:fastq])
while kseq.read!
  n+=1;STDERR.printf("Reading -- %d\r",n) if (n%10_000).zero?

  comment = kseq.comment
  if comment
    head = "#{kseq.name} #{comment}"
  else
    head = kseq.name
  end

  records << ["@#{head}", kseq.seq, "+", kseq.qual]
end

num_records = records.count

FileUtils.mkdir_p opts[:outdir]

opts[:num].times do |n|
  File.open(File.join(opts[:outdir], "#{opts[:basename]}.#{n}.fq"), "w") do |f|
    STDERR.puts "Writing #{f.path}"
    num_records.times do |rec_num|
      STDERR.printf("Writing record -- %d\r", rec_num) if (rec_num%10_000).zero?
      f.puts records[rand 0 .. (num_records-1)]
    end
  end
end
