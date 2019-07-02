groups = Entourage.where(
  group_type: [:action, :outing],
  status: [:open, :closed, :blacklisted]
)

data = []

groups = groups.includes(:sensitive_words_check).order(created_at: :desc)
groups.each do |group|
  # statut
  #
  status = group.status == 'blacklisted' ? 'blocked' : 'validated'


  # texte
  #
  text   = [
    group.title,
    group.description
  ].compact.join(' ')

  # replace newlines and multi-whitespace sequences by a single space
  text.gsub!(/\s+/, ' ')


  # justification
  #
  word_matches = group.sensitive_words_check&.matches || {}
  category_matches = {}

  word_matches.each do |words, category_ids|
    words = words.flatten.uniq
    categories = SensitiveWord.where(id: category_ids).pluck(:category).uniq

    categories.each do |category|
      category_matches[category] ||= []
      category_matches[category] = (category_matches[category] + words).uniq.sort
    end
  end

  matches = category_matches.sort_by(&:first).map { |category, words|
    "#{category}(#{words.join('\\')})"
  }.join('|');


  data.push [
    status,
    text,
    matches
  ]
end


# File generation
#
# Azure Machine Learning Studio's parser seems quite brittle and we had to make
# several tentatives until we found a format that was working.
#
# - TSV instead of CSV: quoting columns values was not working
# - removing newlines in values (maybe \n in values and \r\n for rows would work?)
# - CR+LF newlines between rows (not sure that's necessary in the end)
# - UTF-8, but some characters are not supported (wide characters? we had emoji)
csv_options = {
  col_sep: "\t",    # tabulation -> .tsv
  row_sep: "\r\n",  # \r\n: standard Windows newline
  headers: [:statut, :texte, :justification],
  write_headers: true
}

CSV.open("data.tsv", "wb", csv_options) do |csv|
  data.each do |line|
    # Encode to UTF-8 to ISO-8859-1 then back to UTF-8 to remove some
    # special characters that caused problems (emoji?).
    # There has to be a better way to do this but it worked =)
    line.map! do |value|
      value.encode("ISO-8859-1", undef: :replace, replace: ' ').encode("UTF-8")
    end
    csv << line
  end
end
