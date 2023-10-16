module TranslationServices
  # supported: ChatMessage, Entourage, Neighborhood (see TranslationObserver)

  class Translator
    BASE_URI = "https://translate.google.com/m?sl=%s&tl=%s&q=%s"

    attr_reader :record

    def initialize record
      @record = record
    end

    # records translation in translations table
    def translate!
      return unless translation_keys.any?

      translation_keys.each do |translation_key|
        translate_field!(translation_key)
      end
    end

    def translate_field! translation_key
      return unless original_text = @record.send(translation_key)
      return unless original_text.present?

      translation = Translation.find_or_initialize_by(instance: @record, instance_field: translation_key)

      ::Translation::LANGUAGES.each do |language|
        translation[language] = text_translation(original_text, language)
      end

      translation.save
    end

    # finds the record translation, in a given lang, from translations table
    def translate lang, field
      return unless lang
      return unless ::Translation::LANGUAGES.include?(lang.to_sym)
      return unless translation = @record.translation(field: field)

      translation.send(lang)
    end

    # translate text into lang
    def text_translation text, lang
      return text if EnvironmentHelper.test? # @bad_code Use stub_request in rspec instead

      uri = URI(BASE_URI % [from_lang, lang, CGI.escape(text)])

      response = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        http.request Net::HTTP::Get.new(uri, {})
      end

      return unless response.present?
      return unless response.code == "200"
      return unless response.body.present?

      Nokogiri::HTML(response.body, nil, 'UTF-8').css('.result-container').text
    end

    private

    def translation_keys
      return [:content] if @record.is_a? ChatMessage
      return [:title, :description] if @record.is_a? Entourage
      return [:name, :description] if @record.is_a? Neighborhood

      []
    end

    def from_lang
      @record.user.lang || ::Translation::DEFAULT_LANG
    end
  end
end
