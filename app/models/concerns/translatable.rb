module Translatable
  extend ActiveSupport::Concern

  BASE_URI = "https://translate.google.com/m?sl=%s&tl=%s&q=%s"
  TRANSLATION_KEYS = {
    chat_message: [:content],
    entourage: [:title, :description],
    neighborhood: [:name, :description]
  }

  included do
    has_one :translation, as: :instance
  end

  # records translation in translations table
  def translate!
    return unless translation_keys.any?

    translation = Translation.find_or_initialize_by(instance: self)
    translation.from_lang = from_lang

    translation_keys.each do |translation_key|
      translate_field!(translation, translation_key)
    end

    translation.save
  end

  def translate_field! translation, translation_key
    return unless self.has_attribute?(translation_key)
    return unless original_text = self.send(translation_key)
    return unless original_text.present?

    Translation::LANGUAGES.each do |language|
      translation.translate!(
        lang: language,
        field: translation_key,
        translation: language == from_lang.to_sym ? original_text : html_translation(original_text, language)
      )
    end
  end

  # translate html into lang
  def html_translation content, lang
    doc = Nokogiri::HTML.fragment(content)

    doc.traverse do |node|
      if node.text? && !node.content.strip.empty?
        node.content = text_translation(node.content.strip, lang)
      end
    end

    doc.to_html
  end

  # translate text into lang
  def text_translation text, lang
    lang ||= Translation::DEFAULT_LANG

    uri = URI(BASE_URI % [from_lang, lang, CGI.escape(text)])

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request Net::HTTP::Get.new(uri, {})
    end

    return unless response.present?
    return unless response.code == "200"
    return unless response.body.present?

    Nokogiri::HTML(response.body, nil, 'UTF-8').css('.result-container').text
  rescue
    nil
  end

  def field_to_lang field, lang
    return self[field] unless translation
    return self[field] unless t = translation.send(lang)

    t[field] || self[field]
  end

  def completed_translations
    return 0 unless translation

    translation.completed_translations
  end

  def from_lang
    return @from_lang if @from_lang.present?
    return @from_lang = Translation::DEFAULT_LANG unless respond_to?(:user) && user.lang

    @from_lang = user.lang
  end

  def translation_keys
    return TRANSLATION_KEYS[:chat_message] if is_a?(ChatMessage)
    return TRANSLATION_KEYS[:entourage] if is_a?(Entourage)
    return TRANSLATION_KEYS[:neighborhood] if is_a?(Neighborhood)

    []
  end
end
