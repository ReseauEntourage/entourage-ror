module Api
  module V1
    module Neighborhoods
      class UnauthorizedNeighborhood < StandardError; end

      class ChatMessagesController < Api::V1::BaseController
        before_action :set_neighborhood, only: [:index, :create, :report, :comments]
        before_action :set_chat_message, only: [:report]
        before_action :authorised_to_see_messages?

        rescue_from Api::V1::Neighborhoods::UnauthorizedNeighborhood do |exception|
          render json: { message: 'unauthorized : you are not accepted in this neighborhood' }, status: :unauthorized
        end

        def index
          messages = @neighborhood.chat_messages.ordered.limit(25)

          if messages.present? && (join_request.last_message_read.nil? || join_request.last_message_read < messages.first.created_at)
            join_request.update(last_message_read: messages.first.created_at)
          end

          render json: messages, each_serializer: ::V1::ChatMessageSerializer
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

          render json: post.children, each_serializer: ::V1::ChatMessageSerializer
        end

        private

        def set_neighborhood
          @neighborhood = Neighborhood.find(params[:neighborhood_id])
        end

        def set_chat_message
          # we want to force chat_message to belong to Neighborhood
          @chat_message = ChatMessage.where(id: params[:chat_message_id], messageable_type: :Neighborhood).first
        end

        def chat_messages_params
          params.require(:chat_message).permit(:content, :message_type, :parent_id)
        end

        def join_request
          @join_request ||= JoinRequest.where(joinable: @neighborhood, user: current_user, status: :accepted).first
        end

        def authorised_to_see_messages?
          raise Api::V1::Neighborhoods::UnauthorizedNeighborhood unless join_request
        end
      end
    end
  end
end
