module V1
  class EntourageImageSerializer < ActiveModel::Serializer
    attributes :id,
               :title,
               :landscape_url,
               :landscape_small_url,
               :portrait_url,
               :portrait_small_url

    def landscape_small_url
      object.landscape_thumbnail_url || object.landscape_url
    end

    def portrait_small_url
      object.portrait_small_url || object.portrait_url
    end
  end
end
