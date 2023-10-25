class Translation < ApplicationRecord
  DEFAULT_LANG = :fr
  LANGUAGES = [:fr, :en, :de, :pl, :ro, :uk, :ar]

  belongs_to :instance, polymorphic: true

  LANGUAGES.each do |language|
    define_method(language) do
      OpenStruct.new(self[language])
    end
  end

  def translate field:, lang:
    self[lang][field]
  end

  def translate! field:, lang:, translation:
    lang = DEFAULT_LANG unless LANGUAGES.include?(lang.to_sym)

    self[lang][field] = translation
  end
end
