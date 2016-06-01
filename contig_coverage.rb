#!/usr/bin/env ruby

Signal.trap("PIPE", "EXIT")

insam = ARGV[0]
outf = ARGV[1]

VERSION = "v0.1.0"

unless ARGV.count == 2
  warn "VERSION: #{VERSION}"
  abort "USAGE: contig_coverage.rb recruitment.bam contig_coverage.txt"
end

`samtools idxstats #{insam} | column_math.rb STDIN '/' 3 2 | transform_column.rb STDIN '*' 1000 5 | cut -f1,2,3,4,6 > #{outf}`
