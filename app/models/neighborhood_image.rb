class NeighborhoodImage < ApplicationRecord
  validates_presence_of :title

  def image_url
    return unless self['image_url'].present?

    NeighborhoodImage.image_url_for self['image_url']
  end

  class << self
    def image_url_for url
      storage.read_for(key: url)
    end

    def storage
      Storage::Client.public_images
    end

    def from_absolute_to_relative_url url
      return unless url.present?

      url = url.gsub /(.)*neighborhood_images\//, ''
      url = url.gsub /\?(.)*/, '' if url.include? '?'

      "neighborhood_images/#{url}"
    end
  end
end
