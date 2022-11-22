module V1
  class InappNotificationSerializer < ActiveModel::Serializer
    attributes :id,
      :instance,
      :instance_id,
      :content,
      :completed_at,
      :created_at,
      :image_url

    def image_url
    end
  end
end
