#!/usr/bin/env ruby

# http://www.drive5.com/usearch/manual/opt_uc.html

# Sequences that are centroids are listed twice, once in a S record
# and once in a C record, this sequence will not be listed in an H
# record. Singleton clusters will have an S and a C record but no H
# records.

require "abort_if"

include AbortIf

def leftpad str, withwhat, desired_len
  "#{withwhat * (desired_len - str.length)}#{str}"
end

Signal.trap("PIPE", "EXIT")

abort_if ARGV.length < 2,
         "USAGE -- usearch_to_biom.rb clusters.uc sample1_name " +
         "sample2_name ..."

uc_f = ARGV.shift
samples = ARGV

# assumes that the first thing when split on _ is the sample name
def get_sample name
  name.split("_")[0]
end

clusters = {}
File.open(uc_f, "rt").each_line do |line|
  ary = line.chomp.split "\t"

  type = ary[0]
  cluster_num = ary[1]
  seq_name = ary[8]

  if type == "C" || type == "H"
    if clusters.has_key? cluster_num
      clusters[cluster_num] << get_sample(seq_name)
    else
      clusters[cluster_num] = [get_sample(seq_name)]
    end
  end
end

largest_cluster_name_size =
  clusters.keys.sort_by(&:length).reverse.first.length

puts ["#OTU ID", samples].flatten.join "\t"
clusters.each do |cluster, counts|
  per_sample_counts = samples.map do |sample|
    counts.count sample
  end

  cluster_name = leftpad cluster, "0", largest_cluster_name_size
  puts ["Otu#{cluster_name}", per_sample_counts].flatten.join "\t"
end
