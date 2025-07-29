module SensitiveWordsService
  def self.find_matches string, scope=:all, categories=[]
    result = {
      records: SensitiveWord.none,
      words: {}
    }

    string = string.to_s
    return result if string.blank?

    whitelist = [
      [['grâce', 'Grâce']]
    ]

    regex = regex_for_expressions(whitelist)
    string.gsub!(regex, 'whitelisted')

    predicates = []

    SensitiveWord::MATCH_TYPES.each do |match_type|
      pattern_data = SensitiveWord.pattern(string, match_type)
      predicates.push predicate_for(pattern_data[:pattern], match_type)
      result[:words][match_type] = pattern_data[:words]
    end

    predicates.compact!
    return result if predicates.empty?

    result[:records] =
      SensitiveWord
        .where(scope: SensitiveWord.scopes_for(scope))
        .with_categories(categories)
        .where(predicates.join(' or '))

    result
  end

  def self.has_match? string, scope=:all, categories=[]
    find_matches(string, scope, categories)[:records].exists?
  end

  def self.entourage_text entourage
    [entourage.title, entourage.description].join(' ')
  end

  def self.analyze_entourage entourage_id
    return unless entourage = Entourage.find_by_id(entourage_id)

    matches = entourage_matches(entourage)
    check = entourage.sensitive_words_check || entourage.build_sensitive_words_check

    unless check.persisted? && (matches.keys.uniq - check.matches.keys.uniq).empty?
      check.status = matches.any? ? :require_moderation : :validated
      check.matches = matches
      check.save!
    end

    check.status.to_sym
  end

  def self.entourage_matches entourage
    match_data = find_matches(entourage_text(entourage), :public)

    words_for_token = match_data[:words]
    matches = {}

    match_data[:records].each do |match|
      tokens = match.pattern.strip.split(' ')
      words = tokens.map { |token| words_for_token[match.match_type][token] }
      (matches[words] ||= []).push match.id
    end

    matches
  end

  def self.regex_for_expressions expressions
    expressions = expressions
      .sort_by { |e| e.length }.reverse
      .map do |expression|
        words = expression.map do |word_variants|
          if word_variants.length == 1
            word_variants.first
          else
            '(' + word_variants.uniq.join('|') + ')'
          end
        end
        if words.count == 1
          words.first
        else
          words.join('[^[:alnum:]]+')
        end
      end

    /(?<![[:alnum:]])(#{expressions.uniq.join('|')})(?![[:alnum:]])/
  end

  def self.highlight(string, expressions, &)
    return string if string.blank? || expressions.empty?
    regex = regex_for_expressions expressions
    string.gsub(regex, &).html_safe
  end

  def self.highlight_entourage entourage, options={}
    options[:class] ||= 'highlight'

    if entourage.sensitive_words_check&.status&.to_sym == :validated
      matches = {}
    else
      matches = entourage.sensitive_words_check&.matches || {}
    end

    words = matches.keys

    highlighter = -> (match) do
      %{<span class="#{options[:class]}">#{match}</span>}
    end

    {
      matches: matches,
      title: highlight(entourage.title, words, &highlighter),
      description: highlight(entourage.description, words, &highlighter)
    }
  end

  def self.enable_callback
    !Rails.env.test?
  end

  private

  def self.predicate_for pattern, match_type
    return if pattern.blank?

    pattern = ApplicationRecord.connection.quote(pattern)
    "(match_type = '%s' and position(pattern in %s) > 0)" % [match_type, pattern]
  end


  module EntourageCallback
    extend ActiveSupport::Concern

    included do
      after_commit :check_sensitive_words
    end

    private

    def check_sensitive_words
      return unless SensitiveWordsService.enable_callback
      return unless community == 'entourage' && group_type.in?(['action', 'outing'])
      return unless (['title', 'description'] & previous_changes.keys).any?

      AsyncService.new(SensitiveWordsService).analyze_entourage(id)
    end
  end
end
