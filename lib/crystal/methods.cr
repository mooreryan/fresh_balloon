def each_fa_record(fname)
  in_header = false
  lineno = 0
  header = ""
  seq = ""

  File.open(fname).each_line do |line|
    lineno += 1

    if line.starts_with?(">") && lineno == 1
      header = line.chomp[1..-1]
    elsif line.starts_with?(">")
      yield(header, seq)

      header = line.chomp[1..-1]
      seq = ""
    elsif !line.starts_with?(">")
      seq += line.chomp
    end
  end

  yield(header, seq)
end

def each_fq_record(fname)
  count = 0
  header = ""
  sequence = ""
  description = ""
  quality = ""

  File.open(fname).each_line do |line|
    line = line.chomp

    case count % 4
    when 0
      header = line[1..-1]
    when 1
      sequence = line
    when 2
      description = line[1..-1]
    when 3
      quality = line
      yield(header, sequence, description, quality)
    end

    count += 1
  end
end

def first_char(fname)
  char = ""

  File.open(fname).each_line { |line| char = line[0]; break }

  char
end

def each_record(fname)
  type = first_char(fname)

  if type == '@'
    each_fq_record(fname) do |head, seq, _, _|
      yield(head, seq)
    end
  elsif type == '>'
    each_fa_record(fname) do |head, seq|
      yield(head, seq)
    end
  else
    abort "ERROR: File #{fname} doesn't look like fastA or fastQ"
  end
end
