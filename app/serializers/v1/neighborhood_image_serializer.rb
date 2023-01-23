module V1
  class NeighborhoodImageSerializer < ActiveModel::Serializer
    attributes :id,
               :title,
               :image_url

    def image_url
      object.image_url_with_size :medium
    end
  end
end
