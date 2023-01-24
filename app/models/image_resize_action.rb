class ImageResizeAction < ApplicationRecord
  # sizes: small, medium, high

  default_scope { where(status: :OK) }

  scope :with_bucket_and_path, -> (bucket, path) {
    where(bucket: bucket, path: path)
  }

  class << self
    def find_path_for bucket:, path:, size:
      return path if size.respond_to?(:to_sym) && size.to_sym == :original
      return path unless image_resize_action = find_by_bucket_and_path_and_destination_size(bucket, path, size)

      image_resize_action.destination_path
    end
  end
end
