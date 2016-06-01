#!/usr/bin/env ruby

VERSION = 0.1.0

Signal.trap("PIPE", "EXIT")

if ARGV.count < 4
  warn "VERSION: v#{VERSION}"
  abort "USAGE: column_math.rb fname.txt operation column1 column2 ..."
end

fname = ARGV.shift
op = ARGV.shift
columns = ARGV

warn "File: #{fname}"
warn "Operation #{op.to_sym.inspect}"
warn "Columns requested: #{columns.inspect}"

File.open(fname).each_line do |line|
  ary = line.chomp.split "\t"

  result = columns.map { |colnum| ary[colnum.to_i].to_f }.reduce(op.to_sym)

  puts [ary, result].join "\t"
end
