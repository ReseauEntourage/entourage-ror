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
                  last_name: last_element.user.last_name.presence&.first
              }
          }
        elsif last_element.is_a?(JoinRequest)
          {
              text: last_join_request_text,
              author: nil
          }
        end
      end

      def last_element
        @last_element ||= begin
          user_join_request = object.join_requests.includes(:user).where(user_id: scope[:user].id).last
          if user_join_request.is_accepted?
            last_chat_message = object.chat_messages.includes(:user).order("created_at ASC").last
            last_join_request = object.join_requests.pending.order("created_at ASC").last
            [last_chat_message, last_join_request].compact.sort_by {|o| o.created_at}.reverse[0]
          else
            user_join_request
          end
        end
      end

      def last_join_request_text
        if last_element.is_pending?
          if last_element.user == scope[:user]
            "Votre demande est en attente."
          else
            "1 nouvelle demande pour rejoindre votre #{GroupService.name(object)}."
          end
        elsif last_element.is_accepted?
          return "Vous avez rejoint #{GroupService.name(object, :l)}."
        elsif last_element.is_cancelled?
          return "Vous avez annulé votre demande."
        elsif last_element.is_rejected?
          return "Votre demande a été rejetée."
        end
      end
    end
  end
end
