module V1
  module Myfeeds
    module LastMessage
      def include_last_message?
        scope[:include_last_message]
      end

      def last_message
        if object.user_id == current_join_request.user_id && object.status == 'open'
          pending_requests = object.join_requests.where(status: :pending).count
          if pending_requests > 0
            requests_text = pending_requests == 1 ? "1 personne demande" : "#{pending_requests} personnes demandent"
            return {
              text: "#{requests_text} à rejoindre votre #{GroupService.name(object)}.",
              author: nil
            }
          end
        end

        if last_element.is_a?(ChatMessage)
          {
              text: last_element.content,
              author: {
                  first_name: last_element.user.first_name,
                  last_name: last_element.user.last_name.presence&.first,
                  display_name: UserPresenter.new(user: last_element.user).display_name,
                  id: last_element.user.id
              }
          }
        elsif last_element.is_a?(JoinRequest)
          {
              text: last_join_request_text,
              author: nil
          }
        end
      end

      def last_chat_message
        if scope.key?(:last_chat_message)
          scope[:last_chat_message]
        else
          object.chat_messages.includes(:user).order("created_at ASC").last
        end
      end

      def last_join_request
        if scope.key?(:last_join_request)
          scope[:last_join_request]
        else
          object.join_requests.pending.order("created_at ASC").last
        end
      end

      def last_element
        @last_element ||= begin
          if current_join_request.is_accepted?
            [last_chat_message, last_join_request].compact.sort_by {|o| o.created_at}.reverse[0]
          else
            current_join_request
          end
        end
      end

      def last_join_request_text
        if last_element.is_pending?
          if last_element.user_id == scope[:user].id
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
