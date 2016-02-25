module Api
  module V1
    module Tours
      class UnauthorisedTour < StandardError; end

      class ChatMessagesController < Api::V1::BaseController
        before_action :set_tour
        before_action :authorised_to_see_messages?

        rescue_from Api::V1::Tours::UnauthorisedTour do |exception|
          render json: {message: 'unauthorized : you are not accepted in this tour'}, status: :unauthorized
        end

        def index
          before = params[:before] ? DateTime.parse(params[:before]) : DateTime.now
          messages = @tour.chat_messages.ordered.before(before).limit(25)
          #TODO: move into a LastMessageRead class
          if messages.present? && (tour_user.last_message_read.nil? || tour_user.last_message_read < messages.last.created_at)
            tour_user.update(last_message_read: messages.last.created_at)
          end

          render json: messages, each_serializer: ::V1::ChatMessageSerializer
        end

        def create
          message = @tour.chat_messages.new(chat_messages_params)
          message.user = @current_user
          if message.save
            tour_user.update(last_message_read: message.created_at)
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

        def tour_user
          @tour_user ||= ToursUser.where(tour: @tour, user: @current_user, status: "accepted").first
        end

        def authorised_to_see_messages?
          raise Api::V1::Tours::UnauthorisedTour unless tour_user
        end
      end
    end
  end
end