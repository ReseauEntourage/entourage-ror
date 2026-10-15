module EmbeddingServices
  # text embedded for each kind of record: what a person reads to know what it is about
  module Text
    MAX_LENGTH = 2_000

    def self.for record
      parts = case record
      when Entourage
        [record.title, record.description]
      when Neighborhood
        [record.name, record.description]
      when Poi
        [record.name, record.category&.name, record.description]
      when Resource
        [record.name, record.text_description_only]
      else
        raise ArgumentError, "no embedding text for #{record.class.name}"
      end

      text = parts.map { |part| Mentionable.no_html(part.to_s).squish }.reject(&:blank?).join("\n")
      text.truncate(MAX_LENGTH).presence
    end
  end
end
