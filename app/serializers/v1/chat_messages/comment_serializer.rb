module V1
  module ChatMessages
    class CommentSerializer < GenericSerializer
      def has_comments
        false
      end

      def comments_count
        0
      end

      def image_url
        nil
      end
    end
  end
end
