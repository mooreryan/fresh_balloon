require "parse_fasta"
require "set"

blast_f = ARGV[0]
contigs_f = ARGV[1]

names = []
n = 0
File.open(blast_f).each_line do |line|
  n += 1; $stderr.printf("Reading blast: %d\r", n) if (n % 10_000).zero?
  orfname, *rest = line.chomp.split "\t"

  orfmatch = orfname.match(/(.*)_[0-9]+_[0-9]+_[0-9]+$/)

  abort "ERROR -- no match for #{line}" if orfmatch.nil?

  names << orfmatch[1]
end

names = Set.new names

FastaFile.open(contigs_f).each_record_fast do |head, seq|
  n += 1; $stderr.printf("Reading fasta: %d\r", n) if (n % 10_000).zero?
  puts ">#{head}\n#{seq}" if names.include?(head)
end
