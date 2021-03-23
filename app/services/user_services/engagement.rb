module UserServices
  module Engagement
    extend ActiveSupport::Concern

    included do
      has_one :user_denorm

      scope :engaged, -> {
        joins(:user_denorm).where(%{
          last_created_action_id is not null or
          last_join_request_id is not null or
          last_private_chat_message_id is not null or
          last_group_chat_message_id is not null
        })
      }

      scope :not_engaged, -> { joins(:user_denorm).where.not(%{
          last_created_action_id is not null or
          last_join_request_id is not null or
          last_private_chat_message_id is not null or
          last_group_chat_message_id is not null
        }) }
    end

    def engaged?
      return false unless user_denorm

      user_denorm.last_created_action_id.present? ||
        user_denorm.last_join_request_id.present? ||
        user_denorm.last_private_chat_message_id.present? ||
        user_denorm.last_group_chat_message_id.present?
    end

    def last_created_action_id; user_denorm&.last_created_action_id; end
    def last_join_request_id; user_denorm&.last_join_request_id; end
    def last_private_chat_message_id; user_denorm&.last_private_chat_message_id; end
    def last_group_chat_message_id; user_denorm&.last_group_chat_message_id; end

    def last_created_action
      return nil unless last_created_action_id

      Entourage.find_by(id: last_created_action_id)
    end

    def last_join_request
      return nil unless last_join_request_id

      JoinRequest.find_by(id: last_join_request_id)
    end

    def last_join_action
      return nil unless last_join_request_id

      Entourage.find_by(id: join_request.joinable_id)
    end

    def last_private_chat_message
      return nil unless last_private_chat_message_id

      ChatMessage.find_by(id: last_private_chat_message_id)
    end

    def last_group_chat_message
      return nil unless last_group_chat_message_id

      ChatMessage.find_by(id: last_group_chat_message_id)
    end
  end
end
