module V1
  module Myfeeds
    module LastMessage
      def include_last_message?
        scope[:include_last_message]
      end

      def last_message
        return unless last_chat_message.present?

        {
          text: last_chat_message.content,
          author: {
            first_name: last_message_user.first_name,
            last_name: last_message_user.last_name.presence&.first,
            display_name: UserPresenter.new(user: last_message_user).display_name,
            id: last_message_user.id
          }
        }
      end

      def last_chat_message
        @last_chat_message ||= begin
          if scope.key?(:last_chat_message)
            scope[:last_chat_message]
          else
            lazy_last_chat_message
          end
        end
      end

      def last_message_user
        @last_message_user ||= last_chat_message.user
      end
    end
  end
end
