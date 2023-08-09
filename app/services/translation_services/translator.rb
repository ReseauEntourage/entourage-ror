module TranslationServices
  # supported: ChatMessage (see TranslationObserver)

  class Translator
    LANGUAGES = [:fr, :en]
    BASE_URI = "https://translate.google.com/m?sl=%s&tl=%s&q=%s"

    attr_reader :record

    def initialize record
      @record = record
    end

    def translate!
      translation = Translation.find_or_initialize_by(instance_id: record.id, instance_type: record.class.name)
      return if translation.persisted?

      original_text = record.send(translation_key)

      LANGUAGES.each do |language|
        translation[language] = text_translation(original_text, language)
      end

      translation.save
    end

    def translate lang
      return unless LANGUAGES.include?(lang)
      return unless translation = Translation.find_by(instance_id: record.id, instance_type: record.class.name)

      translation.send(lang)
    end

    def text_translation text, lang
      return text if EnvironmentHelper.test?
      uri = URI(BASE_URI % ["fr", lang, text])

      response = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        http.request Net::HTTP::Get.new(uri, {})
      end

      return unless response.present?
      return unless response.code == "200"
      return unless response.body.present?

      Nokogiri::HTML(response.body).css('.result-container').text
    end

    private

    def translation_key
      return :content if record.is_a? ChatMessage
    end
  end
end
