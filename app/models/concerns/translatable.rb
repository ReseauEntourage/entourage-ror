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

    translation_keys.each do |translation_key|
      translate_field!(translation, translation_key)
    end
  end

  def translate_field! translation, translation_key
    return unless self.has_attribute?(translation_key)
    return unless original_text = self.send(translation_key)
    return unless original_text.present?

    Translation::LANGUAGES.each do |language|
      translation.translate!(
        lang: language,
        field: translation_key,
        translation: self.text_translation(original_text, language)
      )
    end

    translation.save
  end

  # translate text into lang
  def text_translation text, lang
    lang ||= Translation::DEFAULT_LANG

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

  def from_lang
    return Translation::DEFAULT_LANG unless self.has_attribute?(:user)

    user.lang || Translation::DEFAULT_LANG
  end

  def translation_keys
    return TRANSLATION_KEYS[:chat_message] if self.is_a?(ChatMessage)
    return TRANSLATION_KEYS[:entourage] if self.is_a?(Entourage)
    return TRANSLATION_KEYS[:neighborhood] if self.is_a?(Neighborhood)

    []
  end
end
