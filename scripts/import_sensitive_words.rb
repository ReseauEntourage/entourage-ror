def usage
  $stderr.puts "Usage: rails runner #{$PROGRAM_NAME} file match_type scope [category]"
  exit 1 unless defined? Rails
  $stderr.puts "  match_type: #{SensitiveWord::MATCH_TYPES.join('|')}"
  $stderr.puts "  scope:      #{SensitiveWord::SCOPES.join('|')}"
  $stderr.puts "  category:   (optional) name or short text describing the word group"
  exit 1
end

usage unless defined? Rails

usage unless ARGV.count.in?([3, 4])

match_type = ARGV[1]
usage unless match_type.in? SensitiveWord::MATCH_TYPES

scope = ARGV[2]
usage unless scope.in? SensitiveWord::SCOPES

category = ARGV[3].presence

File.open(ARGV[0]).each_line do |line|
  word = line.strip
  record = SensitiveWord.new(
    raw: word.strip,
    scope: scope,
    match_type: match_type,
    category: category
  )
  begin
    record.save!
  rescue ActiveRecord::RecordInvalid
    puts "WARN: invalid word: #{word.inspect}"
  rescue ActiveRecord::RecordNotUnique
    existing = SensitiveWord.find_by(pattern: record.pattern)
    if existing.scope == 'public' && record.scope == 'all'
      existing.scope = 'all'
    end
    if existing.match_type == 'exact' && record.match_type == 'stem'
      existing.match_type = 'stem'
    end
    if existing.changed?
      existing.raw = record.raw
      existing.category = record.category
      puts "INFO: changing #{word.inspect} to #{existing.changes}"
      existing.save!
    else
      puts "INFO: already in database: #{word.inspect}"
    end
  end
end
