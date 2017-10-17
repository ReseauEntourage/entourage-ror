module Api
  module V1
    module Entourages
      class UnauthorisedEntourage < StandardError; end

      class ChatMessagesController < Api::V1::BaseController
        before_action :set_entourage
        before_action :authorised_to_see_messages?

        rescue_from Api::V1::Entourages::UnauthorisedEntourage do |exception|
          render json: {message: 'unauthorized : you are not accepted in this entourage'}, status: :unauthorized
        end

        def index
          before = params[:before] ? DateTime.parse(params[:before]) : DateTime.now
          messages = @entourage.chat_messages.includes(:user).ordered.before(before).limit(25)
          #TODO: move into a LastMessageRead class
          if messages.present? && (join_request.last_message_read.nil? || join_request.last_message_read < messages.last.created_at)
            join_request.update(last_message_read: messages.last.created_at)
          end

          render json: messages, each_serializer: ::V1::ChatMessageSerializer
        end

        def create
          chat_builder = ChatServices::ChatMessageBuilder.new(params: chat_messages_params,
                                                              user: current_user,
                                                              joinable: @entourage,
                                                              join_request: join_request)
          chat_builder.create do |on|
            on.success do |message|
              mixpanel.track("Wrote Message in Entourage")
              render json: message, status: 201, serializer: ::V1::ChatMessageSerializer
            end

            on.failure do |message|
              render json: {message: 'Could not create chat message', reasons: message.errors.full_messages}, status: :bad_request
            end

            on.freezed_tour do |message|
              render json: {message: 'Could not create chat message', reasons: 'Tour is freezed'}, status: 422
            end
          end
        end

        private
        def set_entourage
          @entourage = Entourage.visible.find_by_id_or_uuid(params[:entourage_id])
        end

        def chat_messages_params
          params.require(:chat_message).permit(:content)
        end

        def join_request
          @join_request ||= JoinRequest.where(joinable: @entourage, user: @current_user, status: "accepted").first
        end

        def authorised_to_see_messages?
          raise Api::V1::Entourages::UnauthorisedEntourage unless join_request
        end
      end
    end
  end
end