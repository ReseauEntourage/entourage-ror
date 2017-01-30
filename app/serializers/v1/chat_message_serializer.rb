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
        display_name: display_name,
        partner: chat_user.default_partner.nil? ? nil : V1::PartnerSerializer.new(chat_user.default_partner, scope: {user: chat_user}, root: false).to_json
      }
    end

    def display_name
      UserPresenter.new(user: object.user).display_name
    end

    def chat_user
      object.user
    end
  end
end