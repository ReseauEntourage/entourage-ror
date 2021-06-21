module V1
  class EntourageImageSerializer < ActiveModel::Serializer
    attributes :id,
               :title,
               :landscape_url,
               :landscape_small_url,
               :portrait_url,
               :portrait_small_url
  end
end
