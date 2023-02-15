module Api
  module V1
    module Outings
      class UnauthorizedOuting < StandardError; end

      class ChatMessagesController < Api::V1::BaseController
        before_action :set_outing, only: [:index, :show, :create, :destroy, :report, :comments, :presigned_upload]
        before_action :set_chat_message, only: [:show, :destroy, :report]
        before_action :ensure_is_member, only: [:create, :report, :presigned_upload]

        after_action :set_last_message_read, only: [:index]

        rescue_from Api::V1::Outings::UnauthorizedOuting do |exception|
          render json: { message: 'unauthorized : you are not accepted in this outing' }, status: :unauthorized
        end

        def index
          messages = @outing.parent_chat_messages.ordered.page(page).per(per)

          render json: messages, each_serializer: ::V1::ChatMessages::PostSerializer, scope: { current_join_request: join_request }
        end

        def show
          return render json: { message: "Wrong chat_message" }, status: :bad_request unless @chat_message

          render json: @chat_message, serializer: ::V1::ChatMessages::PostSerializer, scope: { current_join_request: join_request, image_size: params[:image_size] }
        end

        def create
          ChatServices::ChatMessageBuilder.new(
            params: chat_messages_params,
            user: current_user,
            joinable: @outing,
            join_request: join_request
          ).create do |on|
            on.success do |message|
              render json: message, status: 201, serializer: ::V1::ChatMessages::GenericSerializer
            end

            on.failure do |message|
              render json: {
                message: 'Could not create chat message', reasons: message.errors.full_messages
              }, status: :bad_request
            end
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

        def report
          return render json: { message: "Wrong chat_message" }, status: :bad_request unless @chat_message

          if report_params[:signals].blank?
            render json: {
              code: 'CANNOT_REPORT_OUTING',
              message: 'signals is required'
            }, status: :bad_request and return
          end

          SlackServices::SignalOutingChatMessage.new(
            chat_message: @chat_message,
            signals: report_params[:signals],
            message: report_params[:message],
            reporting_user: current_user
          ).notify

          head :created
        end

        def comments
          post = Outing.find(params[:outing_id]).chat_messages.where(id: params[:id]).first
          messages = post.children.order(created_at: :asc)

          render json: messages, each_serializer: ::V1::ChatMessages::CommentSerializer, scope: { current_join_request: join_request }
        end

        def presigned_upload
          allowed_types = ChatMessage::CONTENT_TYPES

          unless params[:content_type].in? allowed_types
            type_list = allowed_types.to_sentence(two_words_connector: ' or ', last_word_connector: ', or ')
            return render_error(code: "INVALID_CONTENT_TYPE", message: "Content-Type must be #{type_list}.", status: 400)
          end

          extension = MiniMime.lookup_by_content_type(params[:content_type]).extension
          key = "#{SecureRandom.uuid}.#{extension}"
          url = ChatMessage.presigned_url(key, params[:content_type])

          render json: { upload_key: key, presigned_url: url }
        end

        private

        def chat_messages_params
          params.require(:chat_message).permit(:content, :parent_id, :image_url)
        end

        private

        def set_outing
          @outing = Outing.find(params[:outing_id])
        end

        def set_chat_message
          # we want to force chat_message to belong to Outing
          @chat_message = ChatMessage.where(id: params[:chat_message_id] || params[:id], messageable_type: :Entourage).first
        end

        def report_params
          params.require(:report).permit(:message, signals: [])
        end

        def join_request
          @join_request ||= JoinRequest.where(joinable: @outing, user: current_user, status: :accepted).first
        end

        def ensure_is_member
          raise Api::V1::Outings::UnauthorizedOuting unless join_request
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
