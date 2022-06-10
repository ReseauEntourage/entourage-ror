module V1
  class ResourceSerializer < ActiveModel::Serializer
    attributes :id,
      :name,
      :category,
      :description,
      :image_url,
      :url,
      :watched

    def watched
      return false unless scope[:user].present?

      UsersResource.find_by_resource_id_and_user_id_and_watched(object.id, scope[:user].id, true).present?
    end
  end
end
