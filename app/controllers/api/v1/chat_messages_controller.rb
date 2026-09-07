module Api
  module V1
    class ChatMessagesController < Api::V1::BaseController
      before_action :set_chat_message, only: [:update, :destroy]

      def update
        return render_error(status: :forbidden, code: Api::V1::ErrorCodes::FORBIDDEN, legacy: {message: 'unauthorized'}) if @chat_message.user != current_user

        if @chat_message.deleted?
          message = 'chat_message is already deleted'
          return render_error(status: :unprocessable_entity, code: Api::V1::ErrorCodes::VALIDATION_ERROR, message: message, legacy: {message: message})
        end

        @chat_message.assign_attributes(chat_message_update_params.merge({ status: :updated }))

        if @chat_message.save
          render json: @chat_message, status: 200, serializer: ::V1::ChatMessageSerializer, scope: { user: current_user }
        else
          render_error(status: :unprocessable_entity, code: Api::V1::ErrorCodes::VALIDATION_ERROR, legacy: {
            message: 'Could not update chat_message', reasons: @chat_message.errors.full_messages
          })
        end
      end

      def destroy
        ChatServices::Deleter.new(user: current_user, chat_message: @chat_message).delete do |on|
          on.success do |chat_message|
            render json: chat_message, root: 'user', status: 200, serializer: ::V1::ChatMessageSerializer, scope: { user: current_user }
          end

          on.failure do |chat_message|
            render_error(status: :unprocessable_entity, code: Api::V1::ErrorCodes::VALIDATION_ERROR, legacy: {
              message: 'Could not delete chat_message', reasons: chat_message.errors.full_messages
            })
          end

          on.not_authorized do
            render_error(status: :forbidden, code: Api::V1::ErrorCodes::FORBIDDEN, legacy: {
              message: 'You are not authorized to delete this chat_message'
            })
          end
        end
      end

      private

      def set_chat_message
        @chat_message = ChatMessage.find_by_id_or_uuid!(params[:id])
      end

      def chat_message_update_params
        params.require(:chat_message).permit(:content)
      end
    end
  end
end
