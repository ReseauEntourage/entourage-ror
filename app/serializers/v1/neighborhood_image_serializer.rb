module V1
  class NeighborhoodImageSerializer < ActiveModel::Serializer
    attributes :id,
               :title,
               :image_url
  end
end
