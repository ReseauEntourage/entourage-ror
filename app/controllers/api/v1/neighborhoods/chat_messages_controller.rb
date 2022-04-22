module Api
  module V1
    module Neighborhoods
      class UnauthorizedNeighborhood < StandardError; end

      class ChatMessagesController < Api::V1::BaseController
        before_action :set_neighborhood, only: [:index, :create, :report, :comments, :presigned_upload]
        before_action :set_chat_message, only: [:report]
        before_action :ensure_is_member, except: [:index, :comments]

        after_action :set_last_message_read, only: [:index]

        rescue_from Api::V1::Neighborhoods::UnauthorizedNeighborhood do |exception|
          render json: { message: 'unauthorized : you are not accepted in this neighborhood' }, status: :unauthorized
        end

        def index
          messages = @neighborhood.parent_chat_messages.ordered.page(page).per(per)

          render json: messages, each_serializer: ::V1::ChatMessageSerializer, scope: { current_join_request: join_request }
        end

        def create
          ChatServices::ChatMessageBuilder.new(
            params: chat_messages_params,
            user: current_user,
            joinable: @neighborhood,
            join_request: join_request
          ).create do |on|
            on.success do |message|
              render json: message, status: 201, serializer: ::V1::ChatMessageSerializer
            end

            on.failure do |message|
              render json: {
                message: 'Could not create chat message', reasons: message.errors.full_messages
              }, status: :bad_request
            end
          end
        end

        def report
          return render json: { message: "Wrong chat_message" }, status: :bad_request unless @chat_message

          SlackServices::SignalNeighborhoodChatMessage.new(
            chat_message: @chat_message,
            reporting_user: current_user
          ).notify

          head :created
        end

        def comments
          post = Neighborhood.find(params[:neighborhood_id]).chat_messages.where(id: params[:id]).first
          messages = post.children.order(created_at: :desc)

          render json: messages, each_serializer: ::V1::ChatMessageSerializer, scope: { current_join_request: join_request }
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

        def set_neighborhood
          @neighborhood = Neighborhood.find(params[:neighborhood_id])
        end

        def set_chat_message
          @chat_message = ChatMessage.where(id: params[:chat_message_id], messageable_type: :Neighborhood).first
        end

        def chat_messages_params
          params.require(:chat_message).permit(:content, :message_type)
        end

        def join_request
          @join_request ||= JoinRequest.where(joinable: @neighborhood, user: current_user, status: :accepted).first
        end

        def ensure_is_member
          raise Api::V1::Neighborhoods::UnauthorizedNeighborhood unless join_request
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
