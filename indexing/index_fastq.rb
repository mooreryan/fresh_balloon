#!/usr/bin/env ruby

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
        end

        count += 1
      end
    end
  end
end

index_fastq ARGV[0]
