module V1
  class ChatMessageSerializer < ActiveModel::Serializer
    attributes :id,
               :content,
               :user,
               :created_at,
               :message_type,
               :metadata

    def filter(keys)
      keys -= [:metadata] unless object.message_type.in?(['outing', 'status_update'])
      keys
    end

    def user
      # TODO(partner)
      {
        id: chat_user.id,
        avatar_url: UserServices::Avatar.new(user: chat_user).thumbnail_url,
        display_name: display_name,
        partner: nil # chat_user.default_partner.nil? ? nil : JSON.parse(V1::PartnerSerializer.new(chat_user.default_partner, scope: {user: chat_user}, root: false).to_json)
      }
    end

    def display_name
      UserPresenter.new(user: object.user).display_name
    end

    def chat_user
      object.user
    end

    def metadata
      object.metadata.except(:$id)
    end
  end
end
