#!/usr/bin/env ruby

def run_it *a, &b
  exit_status, stdout, stderr = systemu *a, &b

  puts stdout unless stdout.empty?
  $stderr.puts stderr unless stderr.empty?

  exit_status.exitstatus
end

def run_it! *a, &b
  exit_status = run_it *a, &b

  abort_unless exit_status.zero?,
               "ERROR: non-zero exit status (#{exit_status})"

  exit_status
end

def bowtie index, infastq, outbam, threads
  bowtie = "/home/moorer/bin/bowtie2"
  samtools = "/home/moorer/bin/samtools"

  cmd = "#{bowtie} -x #{index} " +
        "--no-unal " +
        "--threads #{threads} " +
        "--very-sensitive-local " +
        "--local " +
        "-U #{infastq} | " +
        "#{samtools} view " +
        "--threads #{threads} -b -S - " +
        "> #{outbam}"

  STDERR.puts "Running #{cmd}"
  run_it! cmd
end

require "trollop"
require "parse_fasta"
require "fileutils"
require "systemu"
require "abort_if"

include AbortIf

Signal.trap("PIPE", "EXIT")

opts = Trollop.options do
  version "Version: 0.1.0"
  banner <<-EOS

  Outputs monte carlo bootstraps of the input fastq file, then uses
  bowtie for recruitment to the given index. #BootstrappedRecruitment

  Note: reads whole file into memory

  Options:
  EOS

  opt(:fastq, "Input FASTQ", type: :string)
  opt(:num, "Number of bootstraps", type: :integer, default: 3)
  opt(:basename, "Basename of output files", type: :string,
      default: "sample")
  opt(:outdir, "Output directory", type: :string, default: ".")
  opt(:index, "Bowtie2 index", type: :string)
  opt(:threads, "Number of threads", type: :integer, default: 1)
end

abort_unless_file_exists opts[:fastq]
abort_unless_file_exists opts[:index]

STDERR.puts "Reading records"
records = []
n = 0
FastqFile.open(opts[:fastq]).each_record_fast do |head, seq, desc, qual|
  n+=1;STDERR.printf("Reading -- %d\r",n) if (n%10_000).zero?
  records << ["@#{head}", seq, "+#{desc}", qual]
end

num_records = records.count

FileUtils.mkdir_p opts[:outdir]

opts[:num].times do |n|
  this_fastq = File.join opts[:outdir], "#{opts[:basename]}.#{n}.fq"
  outbam = File.join opts[:outdir], "#{opts[:basename]}.#{n}.bam"

  File.open(this_fastq, "w") do |f|
    STDERR.puts "Writing #{f.path}"

    # write the file
    num_records.times do |rec_num|
      STDERR.printf("Writing record -- %d\r", rec_num) if (rec_num%10_000).zero?
      f.puts records[rand 0 .. (num_records-1)]
    end

    bowtie opts[:index], f, outbam, opts[:threads]

    FileUtils.rm f.path
  end
end
