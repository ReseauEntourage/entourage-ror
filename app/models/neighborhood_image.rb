class NeighborhoodImage < ApplicationRecord
  validates_presence_of :title

  # defines relationships for each image size (ie. image_url_high)
  [:high, :medium, :small].each do |size|
    # has_one :image_url_high
    # has_one :image_url_medium
    # has_one :image_url_small
    has_one :"image_url_#{size}", -> {
      where(bucket: BUCKET_NAME, destination_size: size)
    }, class_name: 'ImageResizeAction', foreign_key: :path, primary_key: :image_url

    delegate :destination_path, to: :"image_url_#{size}", prefix: true, allow_nil: true

    # image_url_high_or_default
    # image_url_medium_or_default
    # image_url_small_or_default
    define_method "image_url_#{size}_or_default" do
      send(:"image_url_#{size}_destination_path") || self['image_url']
    end
  end

  def image_url
    return unless self['image_url'].present?

    NeighborhoodImage.image_url_for self['image_url']
  end

  def image_url_with_size size
    return unless self['image_url'].present?

    NeighborhoodImage.image_url_for_with_size(self['image_url'], size)
  end

  class << self
    def image_url_for url
      storage.public_url(key: url)
    end

    def image_url_for_with_size url, size = :medium
      storage.public_url_with_size(key: url, size: size)
    end

    def storage
      Storage::Client.images
    end
  end

  BUCKET_NAME = self.storage.bucket_name
end
