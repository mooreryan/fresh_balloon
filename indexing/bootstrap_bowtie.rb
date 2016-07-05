require "abort_if"
require "trollop"
require "fileutils"
require "systemu"

include AbortIf

now = Time.now.strftime("%Y-%m-%d_%H-%M-%S.%L")
LOG = File.join File.dirname(__FILE__), "bootstrap_bowtie.log.#{now}.txt"

def say_it cmd
  logger.info "Running #{cmd}"
end

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

def bowtie_index bowtie, infastq
  # TODO check if index already exists
  cmd = "#{bowtie}-build #{infastq} #{infastq} >> #{LOG} 2>&1"

  say_it cmd
  run_it! cmd
end

def bowtie bowtie, samtools, index, infastq, outbam, threads
  cmd = "#{bowtie} -x #{index} " +
        "--no-unal " +
        "--non-deterministic " +
        "--threads #{threads} " +
        "--very-sensitive-local " +
        "--local " +
        "-U #{infastq} 2>> #{LOG} | " +
        "#{samtools} view " +
        "--threads #{threads} -S -b | " +
        "#{samtools} sort --threads #{threads} " +
        "> #{outbam} 2>> #{LOG}"

  say_it cmd
  run_it! cmd

  cmd = "#{samtools} index #{outbam} #{outbam}.bai"

  say_it cmd
  run_it! cmd
end

def depth samtools, cov_var, inbam, outf
  cmd = "#{samtools} depth -aa #{inbam} | #{cov_var} > #{outf} 2>> #{LOG}"

  say_it cmd
  run_it! cmd
end

def index_fastq fname
  File.open(fname, "rt") do |f|
    File.open(fname + ".fqi", "w") do |outf|
      count = 0
      seq_num = 0
      seq_offset = 0
      qual_offset = 0

      lines = []
      f.each_line do
        case count
        when 0 # header
          seq_offset = f.tell
        when 1 # seq

        when 2 # desc
          qual_offset = f.tell
        when 3 # qual
          count = -1

          outf.puts "#{seq_num}\t#{seq_offset}\t#{qual_offset}"

          seq_num += 1
        end

        count += 1
      end
    end
  end
end

def read_record f, idx_ary
  seq_offset = idx_ary[0]
  qual_offset = idx_ary[1]

  f.seek seq_offset, IO::SEEK_SET
  seq = f.readline.chomp

  f.seek qual_offset, IO::SEEK_SET
  qual = f.readline.chomp

  [seq, qual]
end

Signal.trap("PIPE", "EXIT")

opts = Trollop.options do
  version "Version: 0.1.0"
  banner <<-EOS

  Outputs monte carlo bootstraps of the input fastq file, then uses
  bowtie for recruitment to the given index. #BootstrappedRecruitment

  Note: reads whole file into memory

  Note: Say you have 10,000 seqs. Each bootstrap will have 10,000 seqs
  in it, but there will almost certainly be repeats and some seqs
  ommited. Bowtie2 stderr often reports slightly less than 10,000 seqs
  aligned. Not sure what this means.

  Options:
  EOS

  opt(:reads, "Input FASTQ reads", type: :string)
  opt(:references, "References to recruit reads to", type: :string)
  opt(:num, "Number of bootstraps", type: :integer, default: 3)
  # opt(:basename, "Basename of output files", type: :string,
  #     default: "sample")
  opt(:outdir, "Output directory", type: :string, default: ".")
  opt(:threads, "Number of threads", type: :integer, default: 1)
  opt(:bowtie, "Path to bowtie executable", type: :string,
      default: "~/bin/bowtie2")
  opt(:samtools, "Path to samtools executable", type: :string,
      default: "~/bin/samtools")
  opt(:cov_var, "Path to coverage_variance executable", type: :string,
      default: "~/bin/coverage_variance")
end

abort_unless_file_exists opts[:reads]
abort_unless_file_exists opts[:references]

FileUtils.mkdir_p opts[:outdir]

coverage_files = []

num_samples = opts[:num]
fq_f = opts[:reads]

fqi_f = fq_f + ".fqi"

logger.info { "Num samples: #{num_samples}" }
logger.info { "FastQ input: #{fq_f}" }

if File.exists? fqi_f
  logger.info { "Using index: #{fqi_f}" }
else
  logger.info { "Creating index: #{fqi_f}" }

  index_fastq fq_f
end

logger.info { "Reading index" }
index = {}
n = 0
File.open(fqi_f).each_line do |line|
  n += 1; STDERR.printf("READING -- %d\r", n) if (n % 10_000).zero?

  seq, seq_offset, qual_offset = line.chomp.split.map(&:to_i)
  index[seq] = [seq_offset, qual_offset]
end

num_seqs = index.count
logger.info { "Number of sequences in #{fq_f}: #{num_seqs}" }

bowtie_index opts[:bowtie], opts[:references]

boot_seqs_path = File.dirname fq_f
boot_seqs_base = File.basename(fq_f, File.extname(fq_f))

ref_path = File.dirname opts[:references]
ref_base = File.basename(opts[:references],
                         File.extname(opts[:references]))


File.open(fq_f) do |f|
  num_samples.times do |sample|

    boot_seqs_outfile =
      File.join opts[:outdir], "#{boot_seqs_base}.sample_#{sample}.fq"

    outbam =
      File.join opts[:outdir], "#{ref_base}.sample_#{sample}.sorted.bam"
    outcov =
      File.join opts[:outdir], "#{ref_base}.sample_#{sample}.coverage.txt"
    coverage_files << outcov

    File.open(boot_seqs_outfile, "w") do |outf|
      logger.info { "Writing sample #{boot_seqs_outfile}" }
      n = 0
      num_seqs.times do |seq_num|
        n += 1; STDERR.printf("WRITING -- %d\r", n) if (n % 10_000).zero?

        seq, qual = read_record f, index[rand 0 .. (num_seqs-1)]

        outf.puts "@seq_#{seq_num}\n#{seq}\n+\n#{qual}"
      end
    end

    bowtie opts[:bowtie],
           opts[:samtools],
           opts[:references],
           f.path,
           outbam,
           opts[:threads]

    depth opts[:samtools], opts[:cov_var], outbam, outcov
  end
end

logger.info { "Collating coverage info" }
ref_cov = {}
coverage_files.each do |fname|
  File.open(fname).each_line do |line|
    unless line.start_with? "contig\tcontig.length"
      ref, len, cov, *rest = line.chomp.split "\t"

      if ref_cov.has_key? ref
        ref_cov[ref] << cov.to_f
      else
        ref_cov[ref] = [cov.to_f]
      end
    end
  end
end

logger.info { "Writing collated coverage info" }
outf =
  File.join opts[:outdir], "#{ref_base}.collated_coverage.txt"

File.open(outf, "w") do |f|
  f.puts(["reference", opts[:num].
                       times.
                       map { |n| "rep.#{n}" }].
          flatten.join "\t")

  ref_cov.each do |ref, covs|
    abort_unless covs.length == opts[:num],
                 "Missing some coverages for #{ref}"

    f.puts [ref, covs].flatten.join "\t"
  end
end
logger.info { "Collated coverage file: #{outf}" }

logger.info { "Cleaning outdir" }

glob = File.join opts[:outdir], "*.fq"
run_it! "rm #{glob}"

glob = File.join opts[:outdir], "*.coverage.txt"
run_it! "rm #{glob}"

glob = File.join opts[:outdir], "*.bam*"
run_it! "rm #{glob}"


logger.info { "Finished" }
