module V1
  class NeighborhoodImageSerializer < ActiveModel::Serializer
    attributes :id,
               :title,
               :image_url

    def image_url
      return unless url = object.image_url_medium&.path

      NeighborhoodImage::image_url_for(url)
    end
  end
end
