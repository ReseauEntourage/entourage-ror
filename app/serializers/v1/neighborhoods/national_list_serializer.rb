module V1
  module Neighborhoods
    class NationalListSerializer < ListSerializer
      def member
        return false unless scope && scope[:user]

        object.member_ids.include?(scope[:user].id)
      end

      def unread_posts_count
        return unless member

        object.members.pluck(:user_id, :unread_messages_count).to_h[scope[:user].id]
      end
    end
  end
end
