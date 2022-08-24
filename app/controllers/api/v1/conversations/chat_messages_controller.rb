module Api
  module V1
    module Conversations
      class ChatMessagesController < Api::V1::BaseController
        before_action :set_conversation, only: [:index, :create]
        before_action :ensure_is_member, only: [:create]

        after_action :set_last_message_read, only: [:index]

        def index
          messages = @conversation.chat_messages.ordered.page(page).per(per)

          render json: messages, each_serializer: ::V1::ChatMessages::CommonSerializer, scope: { current_join_request: join_request }
        end

        def create
          ChatServices::ChatMessageBuilder.new(
            params: chat_messages_params,
            user: current_user,
            joinable: @conversation,
            join_request: join_request
          ).create do |on|
            on.success do |message|
              render json: message, status: 201, serializer: ::V1::ChatMessages::CommonSerializer
            end

            on.failure do |message|
              render json: {
                message: 'Could not create chat message', reasons: message.errors.full_messages
              }, status: :bad_request
            end
          end
        end

        private

        def ensure_is_member
          render json: { message: 'unauthorized' }, status: :unauthorized unless join_request
        end

        def chat_messages_params
          params.require(:chat_message).permit(:content, :image_url)
        end

        def set_conversation
          @conversation = Entourage.find(params[:conversation_id])
        end

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
