class ImageResizeAction < ApplicationRecord
  SIZES = [:small, :medium, :high, :source, :default]

  default_scope { where(status: :OK) }

  scope :with_bucket_and_path, -> (bucket, path) {
    where(bucket: bucket, path: path)
  }

  scope :with_size, -> (size) {
    where(destination_size: size)
  }

  class << self
    def find_path_for bucket:, path:, size:
      size = :default unless size.respond_to?(:to_sym) && ImageResizeAction::SIZES.include?(size.to_sym)

      return path if size.to_sym == :default
      return path unless image_resize_action = find_by_bucket_and_path_and_destination_size(bucket, path, size)

      image_resize_action.destination_path
    end
  end
end
