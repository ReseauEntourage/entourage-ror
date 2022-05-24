class EntourageImage < ApplicationRecord
  validates_presence_of :title

  def landscape_small_url
    landscape_thumbnail_url || landscape_url
  end

  def portrait_small_url
    portrait_thumbnail_url || portrait_url
  end

  def landscape_thumbnail_url
    return unless self['landscape_thumbnail_url'].present?

    EntourageImage.storage.read_for(key: self['landscape_thumbnail_url'])
  end

  def landscape_url
    return unless self['landscape_url'].present?

    EntourageImage.storage.read_for(key: self['landscape_url'])
  end

  def portrait_thumbnail_url
    return unless self['portrait_thumbnail_url'].present?

    EntourageImage.storage.read_for(key: self['portrait_thumbnail_url'])
  end

  def portrait_url
    return unless self['portrait_url'].present?

    EntourageImage.storage.read_for(key: self['portrait_url'])
  end

  def self.storage
    Storage::Client.images
  end

  def self.from_absolute_to_relative_url url
    return unless url.present?

    url = url.gsub /(.)*entourage_images\/images\//, ''
    url = url.gsub /\?(.)*/, '' if url.include? '?'

    "entourage_images/images/#{url}"
  end
end
