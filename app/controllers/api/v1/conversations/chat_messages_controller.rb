module Api
  module V1
    module Conversations
      class ChatMessagesController < Api::V1::BaseController
        before_action :set_conversation, only: [:index, :create]

        after_action :set_last_message_read, only: [:index]

        def index
          messages = @conversation.chat_messages.ordered.page(page).per(per)

          render json: messages, each_serializer: ::V1::ChatMessages::CommonSerializer, scope: { current_join_request: join_request }
        end

        private

        def join_request
          @join_request ||= JoinRequest.where(joinable: @conversation, user: current_user, status: :accepted).first
        end

        def set_last_message_read
          return unless join_request

          join_request.update(last_message_read: Time.now)
        end

        def page
          params[:page] || 1
        end

        def per
          params[:per] || 25
        end
      end
    end
  end
end
