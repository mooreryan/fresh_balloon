#!/usr/bin/env ruby
require "parallel"

VERSION = "v0.1.0"

unless ARGV.count >= 3
  warn "VERSION: #{VERSION}"
  abort "USAGE: run_multi_blastp.rb threads blast_db seqs1.fa " +
        "seqs2.fa ..."
end

threads = ARGV.shift.to_i
blast_db = ARGV.shift

Parallel.each(ARGV, in_processes: threads) do |fname|
  warn "Running #{fname}"

  outf = "#{fname}.blastp"
  cmd = "time blastp " +
        "-query #{fname} " +
        "-db #{blast_db} " +
        "-outfmt '6 std salltitles' " +
        "-num_threads 1 " +
        "-evalue 1e-10 " +
        "-out #{outf}"

  puts `#{cmd}`
end
