module V1
  module Myfeeds
    module LastMessage
      def include_last_message?
        scope[:include_last_message]
      end

      def last_message
        chat_message = object.chat_messages.includes(:user).order(:created_at).last
        if chat_message
          {
              text: chat_message.content,
              author: {
                  first_name: chat_message.user.first_name,
                  last_name: chat_message.user.last_name
              }
          }
        end
      end
    end
  end
end