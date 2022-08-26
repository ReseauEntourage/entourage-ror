module Api
  module V1
    module Conversations
      class UsersController < Api::V1::BaseController
        before_action :set_conversation, only: [:destroy]
        before_action :ensure_is_action, only: [:destroy]
        before_action :ensure_is_member, only: [:destroy]

        def destroy
          if join_request.update(status: :cancelled)
            render json: join_request, root: :user, status: 200, serializer: ::V1::JoinRequestSerializer, scope: { user: current_user }
          else
            render json: {
              message: 'Could not destroy action participation request', reasons: join_request.errors.full_messages
            }, status: :bad_request
          end
        end

        private

        def set_conversation
          @conversation = Entourage.find(params[:conversation_id])
        end

        def ensure_is_member
          render json: { message: 'unauthorized' }, status: :unauthorized unless join_request
        end

        def ensure_is_action
          render json: { message: 'conversation should be related to an action' }, status: :unauthorized unless @conversation.action?
        end

        def join_request
          @join_request ||= JoinRequest.where(joinable: @conversation, user: current_user, status: :accepted).first
        end
      end
    end
  end
end
