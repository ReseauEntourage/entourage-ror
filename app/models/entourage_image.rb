class EntourageImage < ApplicationRecord
  validates_presence_of :title

  # defines relationships for each image size (ie. landscape_url_high)
  [:landscape_thumbnail_url, :landscape_url, :portrait_thumbnail_url, :portrait_url].each do |image_url|
    [:high, :medium, :small].each do |size|
      # has_one :landscape_thumbnail_url_high
      # has_one :landscape_thumbnail_url_medium
      # has_one :landscape_thumbnail_url_small
      # has_one :landscape_url_high
      # has_one :landscape_url_medium
      # has_one :landscape_url_small
      # has_one :portrait_thumbnail_url_high
      # has_one :portrait_thumbnail_url_medium
      # has_one :portrait_thumbnail_url_small
      # has_one :portrait_url_high
      # has_one :portrait_url_medium
      # has_one :portrait_url_small
      has_one :"#{image_url}_#{size}", -> {
        where(bucket: BUCKET_NAME, destination_size: size)
      }, class_name: 'ImageResizeAction', foreign_key: :path, primary_key: image_url

      delegate :destination_path, to: :"#{image_url}_#{size}", prefix: true, allow_nil: true

      # landscape_thumbnail_url_medium_or_default
      # landscape_url_medium_or_default
      # portrait_thumbnail_url_medium_or_default
      # portrait_url_medium_or_default
      define_method "#{image_url}_#{size}_or_default" do
        send(:"#{image_url}_#{size}_destination_path") || self[image_url]
      end
    end
  end

  def landscape_small_url
    landscape_thumbnail_url || landscape_url
  end

  def portrait_small_url
    portrait_thumbnail_url || portrait_url
  end

  def landscape_thumbnail_url size = :medium
    return unless self['landscape_thumbnail_url'].present?

    EntourageImage.storage.public_url_with_size(key: self['landscape_thumbnail_url'], size: size)
  end

  def landscape_url size = :medium
    return unless self['landscape_url'].present?

    EntourageImage.storage.public_url_with_size(key: self['landscape_url'], size: size)
  end

  def portrait_thumbnail_url size = :medium
    return unless self['portrait_thumbnail_url'].present?

    EntourageImage.storage.public_url_with_size(key: self['portrait_thumbnail_url'], size: size)
  end

  def portrait_url size = :medium
    return unless self['portrait_url'].present?

    EntourageImage.storage.public_url_with_size(key: self['portrait_url'], size: size)
  end

  class << self
    def image_url_for url
      storage.public_url(key: url)
    end

    def storage
      Storage::Client.images
    end
  end

  BUCKET_NAME = self.storage.bucket_name

  def self.from_absolute_to_relative_url url
    return unless url.present?

    url = url.gsub /(.)*entourage_images\/images\//, ''
    url = url.gsub /\?(.)*/, '' if url.include? '?'

    "entourage_images/images/#{url}"
  end
end
