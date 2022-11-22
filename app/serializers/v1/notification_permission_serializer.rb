module V1
  class NotificationPermissionSerializer < ActiveModel::Serializer
    attributes :neighborhood,
      :outing,
      :private_chat_message

    def neighborhood
      object.permissions["neighborhood"]
    end

    def outing
      object.permissions["outing"]
    end

    def private_chat_message
      object.permissions["private_chat_message"]
    end
  end
end
