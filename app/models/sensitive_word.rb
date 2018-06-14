require 'lingua/stemmer'

class SensitiveWord < ActiveRecord::Base
  MATCH_TYPES = %w(stem exact)
  SCOPES = %w(all public)

  before_validation do
    next unless raw.present? && match_type.present? && (raw_changed? || match_type_changed?)
    self.pattern = SensitiveWord.pattern(raw, match_type)[:pattern]
  end

  def self.pattern string, match_type=:exact
    words = string.scan(/[[:alnum:]]+/)

    token_for_word = {}
    tokens = []

    words.each do |word|
      token = ActiveSupport::Inflector.transliterate(word).downcase
      tokens.push token
      token_for_word[word] = token
    end

    if match_type.to_sym == :stem
      unique_tokens = tokens.uniq
      stems = Array(Lingua.stemmer(unique_tokens, language: :fr))
      stem_for_token = Hash[unique_tokens.zip(stems)]
      token_for_word.transform_values! { |token| stem_for_token[token] }
      tokens = tokens.map { |token| stem_for_token[token] }
    end

    words_for_token = {}
    token_for_word.each do |word, token|
      (words_for_token[token] ||= []).push word
    end

    {
      pattern: [nil, *tokens, nil].join(' '),
      words: words_for_token
    }
  end

  def self.scopes_for scope
    case scope.to_sym
    when :public
      [:all, :public]
    when :all
      [:all]
    else
      raise "Unexpected scope #{scope.inspect}"
    end
  end

  validates :raw, :pattern, :match_type, :scope, presence: true
  validates :match_type, inclusion: { in: MATCH_TYPES }
  validates :scope, inclusion: { in: SCOPES }
end
