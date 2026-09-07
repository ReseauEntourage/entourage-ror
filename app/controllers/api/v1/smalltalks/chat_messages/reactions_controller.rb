module Api
  module V1
    module Smalltalks
      module ChatMessages
        class ReactionsController < Api::V1::BaseController
          before_action :set_smalltalk
          before_action :set_chat_message
          before_action :ensure_is_member, only: [:create, :destroy]

          def index
            render json: { reactions: @chat_message.reactions.summary }
          end

          def details
            users = @chat_message.user_reactions.where(reaction_id: params[:id])
              .includes(:user)
              .order(:created_at)
              .page(page)
              .per(per)
              .map(&:user)

            render json: users, each_serializer: ::V1::Users::BasicSerializer
          end

          def users
            user_reactions = @chat_message.user_reactions
              .includes(:user)
              .order(:created_at)
              .page(page)
              .per(per)

            render json: user_reactions, each_serializer: ::V1::UserReactionSerializer
          end

          def create
            reaction = @chat_message.reactions.build(user: current_user, reaction_id: params[:reaction_id])

            if reaction.save
              render json: reaction, status: 201, serializer: ::V1::ReactionSerializer
            else
              render_error(status: :unprocessable_entity, code: Api::V1::ErrorCodes::VALIDATION_ERROR, legacy: {
                message: 'Could not create reaction', reasons: reaction.errors.full_messages
              })
            end
          end

          def destroy
            if reaction_id = @chat_message.reactions.destroy(user: current_user)
              render json: { reaction_id: reaction_id }, status: 200
            else
              render_error(status: :not_found, code: Api::V1::ErrorCodes::NOT_FOUND, legacy: { message: 'Could not delete reaction' })
            end
          end

          private

          def set_smalltalk
            @smalltalk = Smalltalk.find_by_id_through_context(params[:smalltalk_id], params)

            render_error(status: :not_found, code: Api::V1::ErrorCodes::NOT_FOUND, legacy: { message: 'Could not find smalltalk' }) unless @smalltalk.present?
          end

          def set_chat_message
            # we want to force chat_message to belong to Smalltalk
            @chat_message = ChatMessage.where(messageable: @smalltalk).find_by_id_through_context(params[:chat_message_id], params)

            render_error(status: :not_found, code: Api::V1::ErrorCodes::NOT_FOUND, legacy: { message: 'Could not find chat_message' }) unless @chat_message.present?
          end

          def join_request
            @join_request ||= JoinRequest.where(joinable: @smalltalk, user: current_user, status: :accepted).first
          end

          def ensure_is_member
            raise Api::V1::ForbiddenResourceError, 'unauthorized : you are not accepted in this smalltalk' unless join_request
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
end
