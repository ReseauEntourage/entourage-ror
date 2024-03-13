module V1
  class EntourageImageSerializer < ActiveModel::Serializer
    attributes :id,
               :title,
               :landscape_url,
               :portrait_url,

    def landscape_url
      return unless url = object.landscape_url_medium_or_default

      EntourageImage::image_url_for(url)
    end

    def portrait_url
      return unless url = object.portrait_url_medium_or_default

      EntourageImage::image_url_for(url)
    end
  end
end
