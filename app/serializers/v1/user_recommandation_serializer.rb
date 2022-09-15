module V1
  class UserRecommandationSerializer < ActiveModel::Serializer
    attributes :name,
      :type,
      :action,
      :image_url,
      :params

    def type
      object.instance_type.underscore.pluralize
    end

    def action
      return :show if object.join?

      object.action
    end

    def params
      return { id: nil, url: object.instance_url } if object.webview?

      { id: object.instance_id , url: nil }
    end
  end
end
