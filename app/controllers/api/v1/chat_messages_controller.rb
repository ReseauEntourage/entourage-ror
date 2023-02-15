module Api
  module V1
    class ChatMessagesController < Api::V1::BaseController
      before_action :set_chat_message, only: [:destroy]

      def destroy
        ChatServices::Deleter.new(user: current_user, chat_message: @chat_message).delete do |on|
          on.success do |chat_message|
            render json: chat_message, root: "user", status: 200, serializer: ::V1::ChatMessageSerializer, scope: { user: current_user }
          end

          on.failure do |chat_message|
            render json: {
              message: "Could not delete chat_message", reasons: chat_message.errors.full_messages
            }, status: :bad_request
          end

          on.not_authorized do
            render json: {
              message: "You are not authorized to delete this chat_message"
            }, status: :unauthorized
          end
        end
      end

      private

      def set_chat_message
        @chat_message = ChatMessage.find(params[:id])
      end
    end
  end
end
