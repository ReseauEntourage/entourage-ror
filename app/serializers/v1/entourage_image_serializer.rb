module V1
  class EntourageImageSerializer < ActiveModel::Serializer
    attributes :id,
               :title,
               :landscape_url,
               :landscape_small_url,
               :portrait_url

    def landscape_small_url
      object.landscape_url
    end
  end
end
