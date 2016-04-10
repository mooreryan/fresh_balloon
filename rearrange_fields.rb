#!/usr/bin/env ruby

# Copyright 2016 Ryan Moore
# Contact: moorer@udel.edu
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see
# <http://www.gnu.org/licenses/>.

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
