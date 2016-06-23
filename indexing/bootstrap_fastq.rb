require "abort_if"

include AbortIf

def index_fastq fname
  File.open(fname, "rt") do |f|
    File.open(fname + ".fqi", "w") do |outf|
      count = 0
      seq_num = 0
      seq_offset = 0
      qual_offset = 0

      f.each_line do
        case count
        when 0 # header
          seq_offset = f.tell
        when 1 # seq

        when 2 # desc
          qual_offset = f.tell
        when 3 # qual
          count = -1
          outf.puts [seq_num, seq_offset, qual_offset].join "\t"
          seq_num += 1

          if (seq_num % 10_000).zero?
            STDERR.printf("READING -- %d\r", seq_num)
          end
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

num_samples = ARGV[0].to_i
fq_f = ARGV[1]

abort_unless ARGV.count == 2,
             "Usage: bootstrap_fastq.rb num_samples reads.fq"

abort_unless_file_exists fq_f

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

File.open(fq_f) do |f|
  num_samples.times do |sample|

    outpath = File.dirname fq_f
    outbase = File.basename(fq_f, File.extname(fq_f))
    outfile = File.join outpath, "#{outbase}.sample_#{sample}.fq"

    File.open(outfile, "w") do |outf|
      logger.info { "Writing sample #{outfile}" }
      n = 0
      num_seqs.times do |seq_num|
        n += 1; STDERR.printf("WRITING -- %d\r", n) if (n % 10_000).zero?

        seq, qual = read_record f, index[rand 0 .. (num_seqs-1)]

        outf.puts "@seq_#{seq_num}\n#{seq}\n+\n#{qual}"
      end
    end
  end
end
