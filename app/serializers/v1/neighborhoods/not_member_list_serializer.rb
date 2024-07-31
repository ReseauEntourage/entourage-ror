module V1
  module Neighborhoods
    class NotMemberListSerializer < ListSerializer
      def member
        false
      end

      def unread_posts_count
        0
      end
    end
  end
end
