class ImageResizeAction < ApplicationRecord
  SIZES = [:small, :medium, :high, :source, :default]

  default_scope { where(status: :OK) }

  scope :with_bucket_and_path, -> (bucket, path) {
    where(bucket: bucket, path: path)
  }

  scope :with_size, -> (size) {
    where(destination_size: size)
  }

  # Redimensionnements préchargés par preload_paths, le temps de la requête HTTP (ou du job) en
  # cours : Rails remet les CurrentAttributes à zéro au début et à la fin de chaque unité de travail.
  class Preloaded < ActiveSupport::CurrentAttributes
    # { [bucket, size, path] => destination_path, ou nil si l'image n'a pas été redimensionnée }
    attribute :destination_paths
  end

  class << self
    def find_path_for bucket:, path:, size:
      size = :default unless size.respond_to?(:to_sym) && ImageResizeAction::SIZES.include?(size.to_sym)

      return path if size.to_sym == :default

      key = [bucket, size.to_s, path]
      return Preloaded.destination_paths[key] || path if Preloaded.destination_paths&.key?(key)

      return path unless image_resize_action = find_by_bucket_and_path_and_destination_size(bucket, path, size)

      image_resize_action.destination_path
    end

    # Charge en une requête les redimensionnements `size` des images `paths` du bucket `bucket` :
    # find_path_for les sert ensuite sans requête (@see Preloaders::Images)
    def preload_paths bucket:, paths:, size:
      paths = paths.compact.uniq
      return if paths.empty?

      destination_paths = with_bucket_and_path(bucket, paths).with_size(size).pluck(:path, :destination_path).to_h

      Preloaded.destination_paths ||= {}
      paths.each do |path|
        Preloaded.destination_paths[[bucket, size.to_s, path]] = destination_paths[path]
      end
    end
  end
end
