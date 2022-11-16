module V1
  class InappNotificationSerializer < ActiveModel::Serializer
    attributes :id,
      :instance,
      :instance_id,
      :content,
      :created_at
  end
end
