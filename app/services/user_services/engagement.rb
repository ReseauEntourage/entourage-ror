module UserServices
  module Engagement
    extend ActiveSupport::Concern

    included do
      has_one :user_denorm
    end

    def engaged?
      user_denorm.last_created_action_id.present? ||
        user_denorm.last_join_request_id.present? ||
        user_denorm.last_private_chat_message_id.present? ||
        user_denorm.last_group_chat_message_id.present?
    end
  end
end
