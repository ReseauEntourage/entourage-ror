class NeighborhoodImage < ApplicationRecord
  validates_presence_of :title

  def image_url
    return unless self['image_url'].present?

    NeighborhoodImage.storage.url_for(key: self['image_url'])
  end

  def self.storage
    Storage::Client.public_images
  end

  def self.from_absolute_to_relative_url url
    return unless url.present?

    url = url.gsub /(.)*neighborhood_images\//, ''
    url = url.gsub /\?(.)*/, '' if url.include? '?'

    "neighborhood_images/#{url}"
  end
end
