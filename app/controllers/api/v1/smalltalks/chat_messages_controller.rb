module Api
  module V1
    module Smalltalks
      class ChatMessagesController < Api::V1::BaseController
        before_action :set_smalltalk, only: [:index, :create, :update, :comments, :presigned_upload]
        before_action :set_chat_message, only: [:update, :destroy, :comments]
        before_action :ensure_is_member, only: [:create, :presigned_upload]

        after_action :set_last_message_read, only: [:index]

        def index
          messages = @smalltalk.chat_messages.includes(:translation, :user).ordered.page(page).per(per).reverse

          render json: messages, root: :chat_messages, each_serializer: ::V1::ChatMessages::CommonSerializer, scope: { current_join_request: join_request, user: current_user }
        end

        def create
          ChatServices::ChatMessageBuilder.new(
            params: smalltalks_params,
            user: current_user,
            joinable: @smalltalk,
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
              render json: chat_message, root: 'user', status: 200, serializer: ::V1::ChatMessageSerializer, scope: { user: current_user }
            end

            on.failure do |chat_message|
              render json: {
                message: 'Could not delete chat_message', reasons: chat_message.errors.full_messages
              }, status: :bad_request
            end

            on.not_authorized do
              render json: {
                message: 'You are not authorized to delete this chat_message'
              }, status: :unauthorized
            end
          end
        end

        def comments
          post = @smalltalk.chat_messages.where(id: @chat_message.id).first
          messages = post.children.order(created_at: :asc).includes(:translation, :user_reactions)

          render json: messages, each_serializer: ::V1::ChatMessages::CommentSerializer, scope: { current_join_request: join_request, user: current_user }
        end

        def presigned_upload
          allowed_types = ChatMessage::CONTENT_TYPES

          unless params[:content_type].in? allowed_types
            type_list = allowed_types.to_sentence(two_words_connector: ' or ', last_word_connector: ', or ')
            return render_error(code: 'INVALID_CONTENT_TYPE', message: "Content-Type must be #{type_list}.", status: 400)
          end

          extension = MiniMime.lookup_by_content_type(params[:content_type]).extension
          key = "#{SecureRandom.uuid}.#{extension}"
          url = ChatMessage.presigned_url(key, params[:content_type])

          render json: { upload_key: key, presigned_url: url }
        end

        private

        def ensure_is_member
          render json: { message: 'unauthorized' }, status: :unauthorized unless join_request
        end

        def smalltalks_params
          params.require(:chat_message).permit(:content, :image_url)
        end

        def chat_message_update_params
          params.require(:chat_message).permit(:content, :image_url)
        end

        def set_smalltalk
          @smalltalk = Smalltalk.find_by_id_through_context(params[:smalltalk_id], params)

          render json: { message: 'Could not find smalltalk' }, status: 400 unless @smalltalk.present?
        end

        def set_chat_message
          # we want to force chat_message to belong to Outing
          @chat_message = ChatMessage.where(messageable_type: :Smalltalk).find_by_id_through_context(params[:chat_message_id] || params[:id], params)

          render json: { message: 'Could not find chat_message' }, status: 400 unless @chat_message.present?
        end

        def join_request
          @join_request ||= JoinRequest.where(joinable: @smalltalk, user: current_user, status: :accepted).first
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
