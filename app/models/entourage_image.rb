class EntourageImage < ApplicationRecord
  validates_presence_of :title

  def landscape_small_url
    landscape_thumbnail_url || landscape_url
  end

  def portrait_small_url
    portrait_thumbnail_url || portrait_url
  end

  def landscape_thumbnail_url
    storage.url_for key: self['landscape_thumbnail_url']
  end

  def landscape_url
    storage.url_for key: self['landscape_url']
  end

  def portrait_thumbnail_url
    storage.url_for key: self['portrait_thumbnail_url']
  end

  def portrait_url
    storage.url_for key: self['portrait_url']
  end

  def storage
    Storage::Client.images
  end
end
