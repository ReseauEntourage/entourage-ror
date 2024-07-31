module V1
  module Neighborhoods
    class MemberListSerializer < ListSerializer
      def member
        true
      end

      def unread_posts_count
        return unless object.respond_to?(:unread_messages_count)

        object.unread_messages_count
      end
    end
  end
end
