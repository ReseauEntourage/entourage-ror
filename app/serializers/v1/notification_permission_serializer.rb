module V1
  class NotificationPermissionSerializer < ActiveModel::Serializer
    attributes :neighborhood,
      :outing,
      :chat_message,
      :action
  end
end
