module Api
  module V1
    module Tours
      class ChatMessagesController < Api::V1::BaseController
        before_action :set_tour

        def index
          messages = @tour.chat_messages.ordered.page(params[:page]).per(25)
          render json: messages, each_serializer: ::V1::ChatMessageSerializer
        end

        def create
          message = @tour.chat_messages.new(chat_messages_params)
          message.user = @current_user
          if message.save
            render json: message, status: 201, serializer: ::V1::ChatMessageSerializer
          else
            render json: {message: 'Could not create chat message', reasons: message.errors.full_messages}, status: :bad_request
          end
        end

        private
        def set_tour
          @tour = Tour.find(params[:tour_id])
        end

        def chat_messages_params
          params.require(:chat_message).permit(:content)
        end
      end
    end
  end
end