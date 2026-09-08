module Api
  module V1
    module Conversations
      class ChatMessagesController < Api::V1::BaseController
        before_action :set_conversation, only: [:index, :create, :update, :comments, :presigned_upload]
        before_action :set_chat_message, only: [:update, :destroy, :comments]
        before_action :ensure_is_member, only: [:create, :presigned_upload]

        after_action :set_last_message_read, only: [:index]

        def index
          messages = @conversation.chat_messages.includes(:translation, :user, :chat_message_reactions, :user_reactions).ordered.page(page).per(per).reverse

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
              render_error(status: :unprocessable_entity, code: Api::V1::ErrorCodes::VALIDATION_ERROR, legacy: {
                message: 'Could not create chat message', reasons: message.errors.full_messages
              })
            end
          end
        end

        def update
          return render_error(status: :forbidden, code: Api::V1::ErrorCodes::FORBIDDEN, legacy: { message: 'unauthorized' }) if @chat_message.user != current_user
          return render_error(status: :unprocessable_entity, code: Api::V1::ErrorCodes::VALIDATION_ERROR, legacy: { message: 'chat_message is already deleted' }) if @chat_message.deleted?

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

        def comments
          post = @conversation.chat_messages.where(id: @chat_message.id).first
          messages = post.children.order(created_at: :asc).includes(:translation, :user, :chat_message_reactions, :user_reactions)

          render json: messages, each_serializer: ::V1::ChatMessages::CommentSerializer, scope: { current_join_request: join_request, user: current_user }
        end

        def presigned_upload
          allowed_types = ChatMessage::CONTENT_TYPES

          unless params[:content_type].in? allowed_types
            type_list = allowed_types.to_sentence(two_words_connector: ' or ', last_word_connector: ', or ')
            return render_error(code: 'INVALID_CONTENT_TYPE', message: "Content-Type must be #{type_list}.", status: :unprocessable_entity)
          end

          extension = MiniMime.lookup_by_content_type(params[:content_type]).extension
          key = "#{SecureRandom.uuid}.#{extension}"
          url = ChatMessage.presigned_url(key, params[:content_type])

          render json: { upload_key: key, presigned_url: url }
        end

        private

        def ensure_is_member
          render_error(status: :forbidden, code: Api::V1::ErrorCodes::FORBIDDEN, legacy: { message: 'unauthorized' }) unless join_request
        end

        def chat_messages_params
          params.require(:chat_message).permit(:content, :image_url)
        end

        def chat_message_update_params
          params.require(:chat_message).permit(:content, :image_url)
        end

        def set_conversation
          @conversation = Entourage.find_by_id_through_context(params[:conversation_id], params)

          render_error(status: :not_found, code: Api::V1::ErrorCodes::NOT_FOUND, legacy: { message: 'Could not find conversation' }) unless @conversation.present?
        end

        def set_chat_message
          # we want to force chat_message to belong to Outing
          @chat_message = ChatMessage.where(messageable_type: :Entourage).find_by_id_through_context(params[:chat_message_id] || params[:id], params)

          render_error(status: :not_found, code: Api::V1::ErrorCodes::NOT_FOUND, legacy: { message: 'Could not find chat_message' }) unless @chat_message.present?
        end

        def join_request
          @join_request ||= JoinRequest.where(joinable: @conversation, user: current_user, status: :accepted).first
        end

        def set_last_message_read
          return unless join_request

          join_request.set_chat_messages_as_read
        end

        def page
          params[:page] || 1
        end
      end
    end
  end
end
