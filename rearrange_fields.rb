#!/usr/bin/env ruby

require "abort_if"
require "trollop"

include AbortIf
include AbortIf::Assert

Signal.trap("PIPE", "EXIT")

opts = Trollop.options do
  banner <<-EOS

  Works like cut but with option to rearrange output.

  Uses awk if it is available on the system, otherwise, pure ruby.

  Options:
  EOS

  opt(:infile, "Input file", type: :string)
  opt(:fields, "Order of fields to print", type: :string)
  opt(:delimiter, "Infile field delimiter", type: :string,
      default: "\t")
end

awk = `which awk`.chomp

field_str =
  opts[:fields].split(",").map { |field| "$#{field}" }.join(",")

if $?.exitstatus.zero?
  cmd = %Q|#{awk} 'BEGIN {FS=OFS="#{opts[:delimiter]}"} {print #{field_str}}' #{opts[:infile]}|

  $stderr.puts "RUNNING: #{cmd}"
  puts `#{cmd}`
else
  File.open(opts[:infile]).each_line do |line|
    arr = line.chomp.split opts[:delimiter]

    puts opts[:fields].split(",").map { |field| arr[field.to_i-1] }.join(opts[:delimiter])
  end
end
