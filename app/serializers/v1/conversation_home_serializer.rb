module V1
  class ConversationHomeSerializer < ConversationSerializer
    attribute :member
    attribute :chat_messages
    attribute :author, unless: :private_conversation?

    lazy_relationship :chat_messages

    def creator
      return false unless scope && scope[:user]

      object.user_id == scope[:user].id
    end

    def member
      return false unless scope && scope[:user]

      object.member_ids.include?(scope[:user].id)
    end

    def chat_messages
      object.chat_messages.ordered.limit(25).map do |chat_message|
        V1::ChatMessageHomeSerializer.new(chat_message, scope: { current_join_request: current_join_request }).as_json
      end
    end

    def author
      return unless object.user.present?

      {
        id: object.user.id,
        display_name: UserPresenter.new(user: object.user).display_name,
        avatar_url: UserServices::Avatar.new(user: object.user).thumbnail_url,
        created_at: object.user.created_at
      }
    end

    def number_of_unread_messages
      # no need
    end

    def last_message
      # no need
    end

    private

    def current_join_request
      return unless scope[:user]

      @current_join_request ||= JoinRequest.where(joinable: object, user: scope[:user], status: :accepted).first
    end
  end
end
