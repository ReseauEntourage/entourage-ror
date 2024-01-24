module Api
  module V1
    module Conversations
      class ChatMessagesController < Api::V1::BaseController
        before_action :set_conversation, only: [:index, :create, :update]
        before_action :set_chat_message, only: [:update, :destroy]
        before_action :ensure_is_member, only: [:create]

        after_action :set_last_message_read, only: [:index]

        def index
          messages = @conversation.chat_messages.includes(:translation, :user).ordered.page(page).per(per).reverse

          render json: messages, root: :chat_messages, each_serializer: ::V1::ChatMessages::CommonSerializer, scope: { current_join_request: join_request, user: current_user }
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

        def update
          return render json: { message: 'unauthorized' }, status: :unauthorized if @chat_message.user != current_user
          return render json: { message: 'chat_message is already deleted' }, status: :bad_request if @chat_message.deleted?

          @chat_message.assign_attributes(chat_message_update_params.merge({ status: :updated }))

          if @chat_message.save
            render json: @chat_message, status: 200, serializer: ::V1::ChatMessageSerializer, scope: { user: current_user }
          else
            render json: {
              message: 'Could not update chat_message', reasons: @chat_message.errors.full_messages
            }, status: 400
          end
        end

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

        def ensure_is_member
          render json: { message: 'unauthorized' }, status: :unauthorized unless join_request
        end

        def chat_messages_params
          params.require(:chat_message).permit(:content)
        end

        def chat_message_update_params
          params.require(:chat_message).permit(:content)
        end

        def set_conversation
          @conversation = Entourage.find_by_id_through_context(params[:conversation_id], params)

          render json: { message: 'Could not find conversation' }, status: 400 unless @conversation.present?
        end

        def set_chat_message
          @chat_message = ChatMessage.find(params[:chat_message_id] || params[:id])
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
      end
    end
  end
end
