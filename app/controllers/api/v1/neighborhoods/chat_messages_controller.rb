module Api
  module V1
    module Neighborhoods
      class ChatMessagesController < Api::V1::BaseController
        before_action :set_neighborhood, only: [:create]

        def index
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

        private

        def chat_messages_params
          params.require(:chat_message).permit(:content, :message_type)
        end

        def set_neighborhood
          @neighborhood = Neighborhood.find(params[:neighborhood_id])
        end

        def join_request
          @join_request ||= JoinRequest.where(joinable: @neighborhood, user: current_user, status: "accepted").first
        end
      end
    end
  end
end
