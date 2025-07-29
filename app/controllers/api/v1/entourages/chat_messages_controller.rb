module Api
  module V1
    module Entourages
      class UnauthorisedEntourage < StandardError; end

      class ChatMessagesController < Api::V1::BaseController
        before_action :set_entourage_or_handle_conversation_uuid, only: [:index, :create]
        before_action :set_entourage, except: [:index, :create]
        before_action :authorised_to_see_messages?

        rescue_from Api::V1::Entourages::UnauthorisedEntourage do |exception|
          render json: {message: 'unauthorized : you are not accepted in this entourage'}, status: :unauthorized
        end

        def index
          before = params[:before] ? DateTime.parse(params[:before]) : DateTime.now

          messages = @entourage.chat_messages.includes(user: :partner).ordered.before(before).limit(25)

          #TODO: move into a LastMessageRead class
          if messages.present? && (join_request.last_message_read.nil? || join_request.last_message_read < messages.first.created_at)
            join_request.set_chat_messages_as_read_from(messages.first.created_at)
          end

          is_onboarding, mp_params = Onboarding::V1.entourage_metadata(@entourage)

          if is_onboarding &&
             @entourage.chat_messages.where(user_id: current_user.id).empty?
            messages.to_a.push Onboarding::V1.chat_message_for(current_user)
          end

          render json: messages, each_serializer: ::V1::ChatMessageSerializer, scope: { user: current_user }
        end

        def create
          chat_builder = ChatServices::ChatMessageBuilder.new(params: chat_messages_params,
                                                              user: current_user,
                                                              joinable: @entourage,
                                                              join_request: join_request)
          chat_builder.create do |on|
            on.success do |message|
              is_onboarding, mp_params = Onboarding::V1.entourage_metadata(@entourage)
              render json: message, status: 201, serializer: ::V1::ChatMessageSerializer, scope: { user: current_user }
            end

            on.failure do |message|
              render json: {message: 'Could not create chat message', reasons: message.errors.full_messages}, status: :bad_request
            end
          end
        end

        private
        def set_entourage
          @entourage = Entourage.findable_by_id_or_uuid(params[:entourage_id])
        end

        def set_entourage_or_handle_conversation_uuid
          set_entourage and return unless ConversationService.list_uuid?(params[:entourage_id])

          participant_ids = ConversationService.participant_ids_from_list_uuid(params[:entourage_id], current_user: current_user)

          raise ActiveRecord::RecordNotFound unless participant_ids.include?(current_user.id.to_s)

          hash_uuid = ConversationService.hash_for_participants(participant_ids)

          @entourage = Entourage.findable.find_by(uuid_v2: hash_uuid)

          if @entourage.nil?
            @entourage = ConversationService.build_conversation(participant_ids: participant_ids, creator_id: current_user.id)
            @join_request = @entourage.join_requests.to_a.find { |r| r.user_id == current_user.id }
          end
        end

        def chat_messages_params
          metadata_keys = params.dig(:chat_message, :metadata).try(:keys) || []
          params.require(:chat_message).permit(:content, :message_type, metadata: metadata_keys)
        end

        def join_request
          @join_request ||= JoinRequest.where(joinable: @entourage, user: @current_user, status: 'accepted').first
        end

        def authorised_to_see_messages?
          raise Api::V1::Entourages::UnauthorisedEntourage unless join_request
        end
      end
    end
  end
end
