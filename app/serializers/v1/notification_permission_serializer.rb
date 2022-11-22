module V1
  class NotificationPermissionSerializer < ActiveModel::Serializer
    attributes :neighborhood,
      :outing,
      :private_chat_message
  end
end
