#!/usr/bin/env ruby

VERSION = "0.1.0"

Signal.trap("PIPE", "EXIT")

if ARGV.count < 4
  warn "VERSION: v#{VERSION}"
  warn "NOTE: columns are 1 indexed"
  abort "USAGE: column_math.rb fname.txt 'operation' operand column1 column2 ..."
end

fname = ARGV.shift

if fname == "STDIN"
  f = STDIN
else
  f = File.open(fname)
end

operation = ARGV.shift
operand = ARGV.shift.to_f
columns = ARGV.map(&:to_i)

warn "File: #{fname}"
warn "Operation #{operation.to_sym.inspect}"
warn "Operation #{operand}"
warn "Columns requested: #{columns.inspect}"

f.each_line do |line|
  ary = line.chomp.split "\t"

  result = columns.map { |colnum| ary[colnum-1].to_f.send(operation, operand) }

  puts [ary, result].join "\t"
end
