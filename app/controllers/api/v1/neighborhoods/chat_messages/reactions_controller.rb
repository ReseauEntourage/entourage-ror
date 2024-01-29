module Api
  module V1
    module Neighborhoods
      module ChatMessages
        class UnauthorizedReaction < StandardError; end

        class ReactionsController < Api::V1::BaseController
          before_action :set_neighborhood
          before_action :set_chat_message
          before_action :ensure_is_member, only: [:create, :destroy]

          rescue_from Api::V1::Neighborhoods::ChatMessages::UnauthorizedReaction do |exception|
            render json: { message: 'unauthorized : you are not accepted in this neighborhood' }, status: :unauthorized
          end

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
            users = @chat_message.user_reactions
            .includes(:user)
            .order(:created_at)
            .page(page)
            .per(per)
            .map(&:user)

            render json: users, each_serializer: ::V1::Users::BasicSerializer
          end

          def create
            reaction = @chat_message.reactions.build(user: current_user, reaction_id: params[:reaction_id])

            if reaction.save
              render json: reaction, status: 201, serializer: ::V1::ReactionSerializer
            else
              render json: {
                message: "Could not create reaction", reasons: reaction.errors.full_messages
              }, status: 400
            end
          end

          def destroy
            if reaction_id = @chat_message.reactions.destroy(user: current_user)
              render json: { reaction_id: reaction_id }, status: 200
            else
              render json: { message: "Could not delete reaction" }, status: 400
            end
          end

          private

          def set_neighborhood
            @neighborhood = Neighborhood.find_by_id_through_context(params[:neighborhood_id], params)

            render json: { message: 'Could not find neighborhood' }, status: 400 unless @neighborhood.present?
          end

          def set_chat_message
            # we want to force chat_message to belong to Neighborhood
            @chat_message = ChatMessage.where(messageable: @neighborhood).find_by_id_through_context(params[:chat_message_id], params)

            render json: { message: 'Could not find chat_message' }, status: 400 unless @chat_message.present?
          end

          def join_request
            @join_request ||= JoinRequest.where(joinable: @neighborhood, user: current_user, status: :accepted).first
          end

          def ensure_is_member
            raise Api::V1::Neighborhoods::ChatMessages::UnauthorizedReaction unless join_request
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
