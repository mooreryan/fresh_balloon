require "parse_fasta"

blast_f = ARGV[0]
contigs_f = ARGV[1]

names = []
File.open(blast_f).each_line do |line|
  orfname, *rest = line.chomp.split "\t"

  orfmatch = orfname.match(/(.*)_[0-9]+_[0-9]+_[0-9]+$/)

  abort "ERROR -- no match for #{line}" if orfmatch.nil?

  names << orfmatch[1]
end

FastaFile.open(contigs_f).each_record_fast do |head, seq|
  if orfs.any? { |orf| orf == head }
    puts ">#{head}\n#{seq}"
  end
end
