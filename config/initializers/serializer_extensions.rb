class ActiveModel::Serializer
  I18nSerializer = Struct.new(:object, :field, :lang) do
    attr_reader :object, :field, :lang

    def initialize(object, field, lang)
      @object = object
      @field = field
      @lang = lang
    end

    def translation
      return object[field] unless lang && object.translation

      object.translation.with_lang(lang)[field] || object[field]
    end

    def translations
      {
        translation: translation,
        original: object[field],
        from_lang: object.translation&.from_lang || default_lang,
        to_lang: lang || default_lang
      }
    end

    private

    def default_lang
      Translation::DEFAULT_LANG
    end
  end
end
