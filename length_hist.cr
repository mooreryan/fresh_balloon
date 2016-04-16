require "./lib/crystal/methods"

abort "USAGE: length_hist <fname>" if ARGV.size != 1

fname = ARGV[0]
lengths = [] of Int32
n = 0

if !File.exists?(fname)
  abort "ERROR: File #{fname} does not exist"
end
STDERR.puts "LOG -- reading #{fname}"

each_record(fname) do |head, seq|
  n += 1
  STDERR.printf("LOG -- processing: %d\n", n) if (n % 100000) == 0
  lengths << seq.size
end

STDERR.puts

max = lengths.max

num_digits = max.to_s.size

top = max.round(-(num_digits-1))

(0..top).step(1000).each do |len_cutoff|
  count = lengths.select { |len| len >= len_cutoff }.size

  puts [len_cutoff, count].join "\t"
end
