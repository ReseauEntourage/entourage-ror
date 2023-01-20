module V1
  class EntourageImageSerializer < ActiveModel::Serializer
    attributes :id,
               :title,
               :landscape_url,
               :portrait_url,

    def landscape_url
      object.landscape_url :medium
    end

    def portrait_url
      object.portrait_url :medium
    end
  end
end
