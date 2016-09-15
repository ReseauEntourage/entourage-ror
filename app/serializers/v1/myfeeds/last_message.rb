module V1
  module Myfeeds
    module LastMessage
      def include_last_message?
        scope[:include_last_message]
      end

      def last_message
        if last_element.is_a?(ChatMessage)
          {
              text: last_element.content,
              author: {
                  first_name: last_element.user.first_name,
                  last_name: last_element.user.last_name
              }
          }
        elsif last_element.is_a?(JoinRequest)
          {
              text: "1 nouvelle demande pour rejoindre votre entourage",
              author: nil
          }
        end
      end


      def last_element
        @last_element ||= begin
          last_chat_message = object.chat_messages.includes(:user).order("created_at ASC").last
          last_join_request = object.join_requests.pending.order("created_at ASC").last
          [last_chat_message, last_join_request].compact.sort_by {|o| o.created_at}.reverse[0]
        end
      end
    end
  end
end