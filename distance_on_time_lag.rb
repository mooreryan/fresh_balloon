def get_timepoint sample
  begin
    sample.match(/T([0126][248]*)R[0-9]/)[1].to_i
  rescue NoMethodError => e
    abort "Sample: #{sample}"
  end
end

samples = []
sample_timepoints = []
num_samples = -1

File.open(ARGV.first).each_line.with_index do |line, idx|
  if idx.zero?
    _, *samples = line.chomp.split "\t"
    num_samples = samples.count

    sample_timepoints =
      samples.map { |sample| get_timepoint sample }
  else
    sample, *dists = line.chomp.split "\t"
    timepoint = get_timepoint sample

    (idx .. num_samples-1).each do |n|
      begin
        puts [(timepoint - sample_timepoints[n]).abs, dists[n]].join "\t"
      rescue TypeError => e
        abort "n: #{n}"
      end
    end
  end
end
