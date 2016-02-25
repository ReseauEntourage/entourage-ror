module Api
  module V1
    module Tours
      class ChatMessagesController < Api::V1::BaseController
        before_action :set_tour

        def index
          messages = @tour.chat_messages.ordered.page(params[:page]).per(25)
          render json: messages, each_serializer: ::V1::ChatMessageSerializer
        end

        private
        def set_tour
          @tour = Tour.find(params[:tour_id])
        end
      end
    end
  end
end