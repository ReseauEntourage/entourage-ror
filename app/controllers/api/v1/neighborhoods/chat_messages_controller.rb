module Api
  module V1
    module Neighborhoods
      class UnauthorizedNeighborhood < StandardError; end

      class ChatMessagesController < Api::V1::BaseController
        before_action :set_neighborhood, only: [:index, :create, :comments, :presigned_upload]
        before_action :ensure_is_member, except: [:index, :comments]
        after_action :set_last_message_read, only: [:index, :comments]

        rescue_from Api::V1::Neighborhoods::UnauthorizedNeighborhood do |exception|
          render json: { message: 'unauthorized : you are not accepted in this neighborhood' }, status: :unauthorized
        end

        def index
          @messages = @neighborhood.parent_chat_messages.ordered.page(page).per(per)

          render json: @messages, each_serializer: ::V1::ChatMessageSerializer, scope: { current_join_request: join_request }
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
        end

        def comments
          post = Neighborhood.find(params[:neighborhood_id]).chat_messages.where(id: params[:id]).first
          @messages = post.children.order(created_at: :desc)

          render json: @messages, each_serializer: ::V1::ChatMessageSerializer, scope: { current_join_request: join_request }
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

        def set_neighborhood
          @neighborhood = Neighborhood.find(params[:neighborhood_id])
        end

        def join_request
          @join_request ||= JoinRequest.where(joinable: @neighborhood, user: current_user, status: :accepted).first
        end

        def ensure_is_member
          raise Api::V1::Neighborhoods::UnauthorizedNeighborhood unless join_request
        end

        def set_last_message_read
          return unless join_request
          return unless @messages.any?

          most_recent = @messages.first.created_at

          if join_request.present? && (join_request.last_message_read.nil? || join_request.last_message_read < most_recent)
            join_request.update(last_message_read: most_recent)
          end
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
