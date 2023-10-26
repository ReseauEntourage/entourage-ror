class Translation < ApplicationRecord
  DEFAULT_LANG = :fr
  LANGUAGES = [:fr, :en, :de, :es, :pl, :ro, :uk, :ar]

  belongs_to :instance, polymorphic: true

  LANGUAGES.each do |language|
    # allow: record.fr.content for example
    define_method(language) do
      OpenStruct.new(self[language])
    end
  end

  # allow: record.fr.content for example
  def with_lang language
    OpenStruct.new(self[language])
  end

  def translate field:, lang:
    return unless field && lang

    self[lang][field.to_s]
  end

  def translate! field:, lang:, translation:
    return unless field

    lang = DEFAULT_LANG unless LANGUAGES.include?(lang.to_sym)

    self[lang][field.to_s] = translation
  end
end
