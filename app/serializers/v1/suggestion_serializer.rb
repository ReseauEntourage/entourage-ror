# frozen_string_literal: true

module V1
  # Serializes a suggestion hash (candidate, type, score, reasons, distance) for API responses.
  class SuggestionSerializer < ActiveModel::Serializer
    attributes :id, :type, :title, :description, :image_url,
               :distance, :metadata, :cta, :score, :reasons

    def id
      "#{object[:type]}_#{object[:candidate].id}"
    end

    def type
      object[:type]
    end

    def title
      candidate = object[:candidate]
      candidate.respond_to?(:title) ? candidate.title : candidate.name
    end

    def description
      object[:candidate].description
    end

    def image_url
      candidate = object[:candidate]
      return candidate.image_url if candidate.respond_to?(:image_url)

      nil
    end

    def distance
      object[:distance]&.round(1)
    end

    def metadata
      candidate = object[:candidate]
      {
        outing:       -> { outing_metadata(candidate) },
        neighborhood: -> { neighborhood_metadata(candidate) }
      }.fetch(object[:type].to_sym, -> { nil }).call
    end

    def cta
      { outing: 'participate', neighborhood: 'join', user: 'write' }[object[:type].to_sym]
    end

    def score
      object[:score]
    end

    def reasons
      object[:reasons] || []
    end

    private

    def outing_metadata(candidate)
      {
        starts_at: candidate.metadata&.dig('starts_at'),
        location:  [candidate.postal_code].compact.join(', ')
      }
    end

    def neighborhood_metadata(candidate)
      { member_count: candidate.members.count }
    end
  end
end
