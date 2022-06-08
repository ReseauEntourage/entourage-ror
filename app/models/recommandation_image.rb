class RecommandationImage < ApplicationRecord
  validates_presence_of :title

  def image_url
    return unless self['image_url'].present?

    RecommandationImage.image_url_for self['image_url']
  end

  class << self
    def image_url_for url
      storage.public_url(key: url)
    end

    def storage
      Storage::Client.images
    end

    def from_absolute_to_relative_url url
      return unless url.present?

      url = url.gsub /(.)*recommandation_images\//, ''
      url = url.gsub /\?(.)*/, '' if url.include? '?'

      "recommandation_images/#{url}"
    end
  end
end
