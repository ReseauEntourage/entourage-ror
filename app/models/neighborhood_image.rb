class NeighborhoodImage < ApplicationRecord
  validates_presence_of :title

  def image_url
    return unless self['image_url'].present?

    NeighborhoodImage.image_url_for self['image_url']
  end

  class << self
    def image_url_for url
      storage.public_url(key: url)
    end

    def storage
      Storage::Client.images
    end
  end
end
