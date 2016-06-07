module V1
  class ChatMessageSerializer < ActiveModel::Serializer
    attributes :id,
               :content,
               :user,
               :created_at

    def user
      {
        id: chat_user.id,
        avatar_url: UserServices::Avatar.new(user: chat_user).thumbnail_url,
        display_name: display_name
      }
    end

    def display_name
      "#{chat_user.first_name} #{chat_user.last_name[0, 1]}" if [chat_user.first_name, chat_user.last_name].compact.present?
    end

    def chat_user
      object.user
    end
  end
end