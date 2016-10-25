require "parse_fasta"
require "abort_if"
require "trollop"
require "fileutils"
require "set"

include AbortIf
include AbortIf::Assert

def forward_or_reverse str, ftag, rtag
  if str.match(ftag) && str.match(rtag)
    abort_if true,
             "Header #{str} has both forward and reverse tags"
  elsif str.match ftag
    :forward
  elsif str.match rtag
    :reverse
  else
    abort_if true,
             "Header #{str} has neither forward or revere tags"
  end
end

opts = Trollop.options do
  version "Version: v0.1.0"
  banner <<-EOS

  Assumes that the reads have matching header prefixes. Ie

    @asten arosetnaroitneasrtn9328l098234 1:N:0
    @asten t90348092lhaentsenk 2:N:0

  These two would count as paired because their prefixes match and
  they have mathcing Illumina forward reverse header tags (these can
  be set).

  Reads each input file twice to avoid putting sequences into memory.

  Options:
  EOS

  opt :forward,
      "File with forward reads",
      type: :string

  opt :reverse,
      "File with reverse reads",
      type: :string

  opt :forward_tag,
      "Illumina string specifying forward reads",
      type: :string,
      default: "1:N:0:",
      short: "-w"

  opt :reverse_tag,
      "Illumina string specifying reverse reads",
      type: :string,
      default: "2:N:0:",
      short: "-v"

  opt :basename,
      "Basename for the output files",
      type: :string,
      default: "reads"

  opt :outdir,
      "Output directory",
      type: :string,
      default: "."
end

abort_unless_file_exists opts[:forward]
abort_unless_file_exists opts[:reverse]

FileUtils.mkdir_p opts[:outdir]

outbase = File.join opts[:outdir], opts[:basename]

ffout = "#{outbase}.1.fq"
rfout = "#{outbase}.2.fq"
sfout = "#{outbase}.U.fq"

abort_if File.exists?(ffout),
         "Trying to write #{ffout} but a file with this name " +
         "already exists"

abort_if File.exists?(rfout),
         "Trying to write #{ffout} but a file with this name " +
         "already exists"

abort_if File.exists?(sfout),
         "Trying to write #{sfout} but a file with this name " +
         "already exists"

forward_prefixes = []
reverse_prefixes = []

AbortIf.logger.info { "Reading prefixes #{opts[:forward]}" }
# get prefixes in 1
n = 0
ParseFasta::SeqFile.open(opts[:forward]).each_record do |rec|
  n+=1; STDERR.printf("Record -- %d\r", n) if (n % 10000).zero?

  id = rec.header.split(" ")[0]

  orientation = forward_or_reverse rec.header,
                                   opts[:forward_tag],
                                   opts[:reverse_tag]

  abort_if orientation == :reverse,
           "Reverse seq #{rec.header} found in a file that was " +
           "specified as a forward file."

  forward_prefixes << id
end

AbortIf.logger.info { "Reading prefixes #{opts[:reverse]}" }
# get prefixes in 2
n = 0
ParseFasta::SeqFile.open(opts[:reverse]).each_record do |rec|
  n+=1; STDERR.printf("Record -- %d\r", n) if (n % 10000).zero?

  id = rec.header.split(" ")[0]

  orientation = forward_or_reverse rec.header,
                                   opts[:forward],
                                   opts[:reverse_tag]

  abort_if orientation == :forward,
           "Forward seq #{rec.header} found in a file that was " +
           "specified as a reverse file."

  reverse_prefixes << id
end

AbortIf.logger.info { "Identifying paired prefixes" }

fset = Set.new forward_prefixes
rset = Set.new reverse_prefixes

paired_prefixes = fset.intersection rset


begin
  for_outf = File.open ffout, "w"
  rev_outf = File.open rfout, "w"
  un_outf  = File.open sfout, "w"

  AbortIf.logger.info { "Looking for seqs from #{opts[:forward]}" }
  n = 0
  ParseFasta::SeqFile.open(opts[:forward]).each_record do |rec|
    n+=1; STDERR.printf("Record -- %d\r", n) if (n % 10000).zero?

    id = rec.header.split(" ")[0]

    if paired_prefixes.include? id
      for_outf.puts rec
    else
      un_outf.puts rec
    end
  end

  AbortIf.logger.info { "Looking for seqs from #{opts[:reverse]}" }
  n = 0
  ParseFasta::SeqFile.open(opts[:reverse]).each_record do |rec|
    n+= 1; STDERR.printf("Record -- %d\r", n) if (n % 10000).zero?

    id = rec.header.split(" ")[0]

    if paired_prefixes.include? id
      rev_outf.puts rec
    else
      un_outf.puts rec
    end
  end
ensure
  for_outf.close
  rev_outf.close
  un_outf.close
end

AbortIf.logger.info { "Outfiles: #{[ffout, rfout, sfout].join ", "}" }
AbortIf.logger.info { "Num. forward reads: " +
                      "#{fset.count}" }
AbortIf.logger.info { "Num. reverse reads: " +
                      "#{rset.count}" }
AbortIf.logger.info { "Num. surviving read pairs: " +
                      "#{paired_prefixes.count}" }
