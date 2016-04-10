#!/usr/bin/env ruby
require "set"

def file_to_set fname
  s = Set.new

  File.open(fname).each_line { |line| s << line.chomp }

  s
end

f1 = ARGV[0]
f2 = ARGV[1]

s1 = file_to_set f1
s2 = file_to_set f2

s1.each do |elem1|
  s2.each do |elem2|
    if elem1.match elem2
      puts [elem1, elem2].join "\t"
    end
  end
end
