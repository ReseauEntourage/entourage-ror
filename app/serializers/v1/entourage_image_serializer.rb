module V1
  class EntourageImageSerializer < ActiveModel::Serializer
    attributes :id,
               :title,
               :landscape_url,
               :portrait_url
  end
end
