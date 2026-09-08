module Api
  module V1
    module Neighborhoods
      class ChatMessagesController < Api::V1::BaseController
        before_action :set_neighborhood, only: [:index, :show, :create, :update, :destroy, :report, :comments, :presigned_upload]
        before_action :set_chat_message, only: [:show, :update, :destroy, :report, :comments]
        before_action :ensure_is_member, only: [:create, :report, :presigned_upload]

        after_action :set_last_message_read, only: [:index]

        def index
          messages = @neighborhood.parent_chat_messages.excluding_scheduled.no_deleted_without_comments.includes(:translation, :user, :chat_message_reactions, :survey, :user_survey_responses).ordered.page(page).per(per).to_a

          render json: messages, root: :chat_messages, each_serializer: ::V1::ChatMessages::PostSerializer, scope: { current_join_request: join_request, user: current_user, reaction_ids_by_message: ChatMessage.reaction_ids_by_message(messages, current_user) }
        end

        def show
          return render_error(status: :not_found, code: Api::V1::ErrorCodes::NOT_FOUND, legacy: { message: 'Wrong chat_message' }) unless @chat_message

          render json: @chat_message, serializer: ::V1::ChatMessages::PostSerializer, scope: { current_join_request: join_request, user: current_user, image_size: params[:image_size] }
        end

        def create
          ChatServices::ChatMessageBuilder.new(
            params: chat_messages_params,
            user: current_user,
            joinable: @neighborhood,
            join_request: join_request
          ).create do |on|
            on.success do |message|
              render json: message, status: 201, serializer: ::V1::ChatMessages::GenericSerializer
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

        def report
          return render_error(status: :not_found, code: Api::V1::ErrorCodes::NOT_FOUND, legacy: { message: 'Wrong chat_message' }) unless @chat_message

          unless report_params[:signals].present?
            render_error(status: :unprocessable_entity, code: 'CANNOT_REPORT_NEIGHBORHOOD', legacy: {
              code: 'CANNOT_REPORT_NEIGHBORHOOD',
              message: 'signals is required'
            }) and return
          end

          SlackServices::SignalNeighborhoodChatMessage.new(
            chat_message: @chat_message,
            signals: report_params[:signals],
            message: report_params[:message],
            reporting_user: current_user
          ).notify

          head :created
        end

        def comments
          post = @neighborhood.chat_messages.where(id: @chat_message.id).first
          messages = post.children.order(created_at: :asc).includes(:translation, :user, :chat_message_reactions).to_a

          render json: messages, root: :chat_messages, each_serializer: ::V1::ChatMessages::CommentSerializer, scope: { current_join_request: join_request, user: current_user, reaction_ids_by_message: ChatMessage.reaction_ids_by_message(messages, current_user) }
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

        def chat_messages_params
          params.require(:chat_message).permit(:content, :parent_id, :image_url, survey_attributes: [:multiple, choices: []])
        end

        def chat_message_update_params
          params.require(:chat_message).permit(:content, :image_url)
        end

        private

        def set_neighborhood
          @neighborhood = Neighborhood.find_by_id_through_context(params[:neighborhood_id], params)

          render_error(status: :not_found, code: Api::V1::ErrorCodes::NOT_FOUND, legacy: { message: 'Could not find neighborhood' }) unless @neighborhood.present?
        end

        def set_chat_message
          # we want to force chat_message to belong to Neighborhood
          @chat_message = ChatMessage.where(messageable_type: :Neighborhood).excluding_scheduled.find_by_id_through_context(params[:chat_message_id] || params[:id], params)

          render_error(status: :not_found, code: Api::V1::ErrorCodes::NOT_FOUND, legacy: { message: 'Could not find chat_message' }) unless @chat_message.present?
        rescue ActiveRecord::RecordNotFound
          render_error(status: :not_found, code: Api::V1::ErrorCodes::NOT_FOUND, legacy: { message: 'Could not find chat_message' })
        end

        def report_params
          params.require(:report).permit(:message, signals: [])
        end

        def join_request
          @join_request ||= JoinRequest.where(joinable: @neighborhood, user: current_user, status: :accepted).first
        end

        def ensure_is_member
          raise Api::V1::ForbiddenResourceError, 'unauthorized : you are not accepted in this neighborhood' unless join_request
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
