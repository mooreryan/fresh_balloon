#!/usr/bin/env ruby

VERSION = "0.3.0"

Signal.trap("PIPE", "EXIT")

if ARGV.count < 4
  warn "VERSION: v#{VERSION}"
  warn "NOTE: columns are 1 indexed"
  abort "USAGE: column_math.rb fname.txt 'operation' column1 column2 ..."
end

fname = ARGV.shift

if fname == "STDIN"
  f = STDIN
else
  f = File.open(fname)
end

op = ARGV.shift
columns = ARGV.map(&:to_i)

warn "File: #{fname}"
warn "Operation #{op.to_sym.inspect}"
warn "Columns requested: #{columns.inspect}"

f.each_line do |line|
  ary = line.chomp.split "\t"

  result = columns.map { |colnum| ary[colnum-1].to_f }.reduce(op.to_sym)

  puts [ary, result].join "\t"
end
