module V1
  module Myfeeds
    module LastMessage
      def include_last_message?
        scope[:include_last_message]
      end

      def last_message
        chat_message = object.chat_messages.order(:created_at).last
        {text: chat_message.content} if chat_message
      end
    end
  end
end