module V1
  module ChatMessages
    class GenericSerializer < ActiveModel::Serializer
      attributes :id,
                 :content,
                 :user,
                 :created_at,
                 :post_id,
                 :has_comments,
                 :comments_count,
                 :image_url,
                 :read

      def user
        {
          id: object.user.id,
          avatar_url: UserServices::Avatar.new(user: object.user).thumbnail_url,
          display_name: display_name
        }
      end

      def display_name
        UserPresenter.new(user: object.user).display_name
      end

      def post_id
        object.parent_id
      end

      def has_comments
        object.has_children?
      end

      def comments_count
        object.children.count
      end

      def image_url
        return unless object.image_url.present?

        ChatMessage.url_for(object.image_url)
      end

      def read
        return unless current_join_request
        return false unless current_join_request.last_message_read.present?

        object.created_at <= current_join_request.last_message_read
      end

      private

      def current_join_request
        scope[:current_join_request]
      end
    end
  end
end
