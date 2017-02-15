require "abort_if"

include AbortIf

def get_timepoint sample
  begin
    sample.match(/T([0126][248]*)R[0-9]/)[1].to_i
  rescue NoMethodError => e
    abort "Sample: #{sample}"
  end
end

samples = []
sample_timepoints = []
sample_timepoints_comb = []
num_samples = -1
vals_comb = []

desired_seqs_per = ARGV[0]

File.open(ARGV[1]).each_line.with_index do |line, idx|
  if idx.zero?
    _, _, _, *samples = line.chomp.split "\t"
    num_samples = samples.count

    sample_timepoints =
      samples.map { |sample| get_timepoint sample }

    sample_timepoints_comb =
      sample_timepoints.combination(2).
      map { |t1, t2| (t1 - t2).abs }
  else
    _, seqs_per, iter, *vals = line.chomp.split "\t"

    if seqs_per == desired_seqs_per
      vals_comb = vals.combination(2).
                  map { |v1, v2| (v1.to_f - v2.to_f).abs }


      abort_unless vals_comb.count == sample_timepoints_comb.count,
                   "COUNT MISMATCH"

      vals_comb.count.times do |n|
        puts [sample_timepoints_comb[n], vals_comb[n]].join "\t"
      end
    end
  end
end


# File.open(ARGV.first).each_line.with_index do |line, idx|
#   if idx.zero?
#     _, *samples = line.chomp.split "\t"
#     num_samples = samples.count

#     sample_timepoints =
#       samples.map { |sample| get_timepoint sample }
#   else
#     sample, *dists = line.chomp.split "\t"
#     timepoint = get_timepoint sample

#     (idx .. num_samples-1).each do |n|
#       begin
#         puts [(timepoint - sample_timepoints[n]).abs, dists[n]].join "\t"
#       rescue TypeError => e
#         abort "n: #{n}"
#       end
#     end
#   end
# end
