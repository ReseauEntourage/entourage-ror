module V1
  class InappNotificationSerializer < ActiveModel::Serializer
    attributes :instance, :instance_id, :created_at
  end
end
