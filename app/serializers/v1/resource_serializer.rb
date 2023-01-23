module V1
  class ResourceSerializer < ActiveModel::Serializer
    attributes :id,
      :name,
      :is_video,
      :duration,
      :category,
      :description,
      :image_url,
      :url,
      :watched,
      :html

    def watched
      return false unless scope[:user].present?

      UsersResource.find_by_resource_id_and_user_id_and_watched(object.id, scope[:user].id, true).present?
    end

    def html
      ResourceServices::Format.new(resource: object).to_html
    end

    def image_url
      object.image_url_with_size :medium
    end
  end
end
