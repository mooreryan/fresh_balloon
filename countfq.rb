#!/usr/bin/env ruby

total = 0
ARGV.each do |fname|
  if fname.match(/.gz$/)
    num_seqs = (`gunzip -c #{fname} | wc -l`.to_f / 4).round
  else
    num_seqs = (`wc -l #{fname}`.to_f / 4).round
  end

  puts [fname, num_seqs].join "\t"

  total += num_seqs
end

warn "Total seqs: #{total}"
