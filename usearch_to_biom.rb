#!/usr/bin/env ruby

# http://www.drive5.com/usearch/manual/opt_uc.html

# Sequences that are centroids are listed twice, once in a S record
# and once in a C record, this sequence will not be listed in an H
# record. Singleton clusters will have an S and a C record but no H
# records.

require "abort_if"
require "parse_fasta"

include AbortIf

def leftpad str, withwhat, desired_len
  "#{withwhat * (desired_len - str.length)}#{str}"
end

Signal.trap("PIPE", "EXIT")

abort_if ARGV.length < 3,
         "USAGE -- usearch_to_biom.rb clusters.uc centroids.fa sample1_name " +
         "sample2_name ..."

uc_f = ARGV.shift
centroids_f = ARGV.shift
samples = ARGV

centroids = FastaFile.open(centroids_f, "rt").to_hash

# assumes that the first thing when split on _ is the sample name
def get_sample name
  name.split("_")[0]
end

clusters = {}
centroid_to_cluster = {}
File.open(uc_f, "rt").each_line do |line|
  ary = line.chomp.split "\t"

  type = ary[0]
  cluster_num = ary[1]
  seq_name = ary[8]

  centroid_to_cluster[seq_name] = cluster_num if type == "C"

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

biom_f = uc_f + ".biom.tsv"
File.open(biom_f, "w") do |f|
  f.puts ["#OTU ID", samples].flatten.join "\t"
  clusters.each do |cluster, counts|
    per_sample_counts = samples.map do |sample|
      counts.count sample
    end

    cluster_name = leftpad cluster, "0", largest_cluster_name_size
    f.puts ["Otu#{cluster_name}", per_sample_counts].flatten.join "\t"
  end
end

renamed_fasta = centroids_f + ".otu_names.fa"
File.open(renamed_fasta, "w") do |f|
  centroids.each do |name, seq|
    new_name = "Otu#{leftpad(centroid_to_cluster[name], "0", largest_cluster_name_size)}"

    f.puts ">#{new_name}\n#{seq}"
  end
end
