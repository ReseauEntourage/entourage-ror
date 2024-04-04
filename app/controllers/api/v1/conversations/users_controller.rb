module Api
  module V1
    module Conversations
      class UsersController < Api::V1::BaseController
        before_action :set_conversation
        before_action :set_default_join_request, only: [:create, :destroy]
        before_action :set_invite_join_request, only: [:invite]
        before_action :ensure_is_requested_with_uuid_or_uuid_v2, only: [:create]

        def create
          return render json: @join_request, root: "user", status: 201, serializer: ::V1::JoinRequestSerializer, scope: {
            user: current_user
          } if @join_request.present? && @join_request.accepted?

          if @join_request.present?
            @join_request.status = :accepted
          else
            @join_request = JoinRequest.new(joinable: @conversation, user: current_user, role: :participant, status: :accepted)
          end

          if @join_request.save
            render json: @join_request, root: "user", status: 201, serializer: ::V1::JoinRequestSerializer, scope: { user: current_user }
          else
            render json: {
              message: 'Could not create conversation participation request', reasons: @join_request.errors.full_messages
            }, status: :bad_request
          end
        end

        def invite
          return render json: { message: 'inviter should be conversation creator' }, status: :bad_request unless current_user.id == @conversation.user_id

          user = User.find(params[:id])

          return render json: @join_request, root: "user", status: 201, serializer: ::V1::JoinRequestSerializer, scope: {
            user: user
          } if @join_request.present? && @join_request.accepted?

          if @join_request.present?
            @join_request.status = :accepted
          else
            @join_request = JoinRequest.new(joinable: @conversation, user: user, role: :participant, status: :accepted)
          end

          if @join_request.save
            render json: @join_request, root: "user", status: 201, serializer: ::V1::JoinRequestSerializer, scope: { user: user }
          else
            render json: {
              message: 'Could not create conversation participation request', reasons: @join_request.errors.full_messages
            }, status: :bad_request
          end
        end

        def destroy
          if @join_request.update(status: :cancelled)
            render json: @join_request, root: :user, status: 200, serializer: ::V1::JoinRequestSerializer, scope: { user: current_user }
          else
            render json: {
              message: 'Could not destroy action participation request', reasons: @join_request.errors.full_messages
            }, status: :bad_request
          end
        end

        private

        def set_conversation
          @conversation = Entourage.find_by_id_through_context(params[:conversation_id], params)

          render json: { message: 'Could not find conversation' }, status: 400 unless @conversation.present?
        end

        # create should be requested using uuid or uuid_v2 to avoid users to join private conversations they were not invited in
        def ensure_is_requested_with_uuid_or_uuid_v2
          render json: { message: 'conversation uuid or uuid_v2 does not match' }, status: :unauthorized unless [@conversation.uuid, @conversation.uuid_v2].include?(params[:conversation_id])
        end

        def set_default_join_request
          @join_request ||= JoinRequest.where(joinable: @conversation, user: current_user).first
        end

        def set_invite_join_request
          @join_request ||= JoinRequest.where(joinable: @conversation, user: params[:id]).first
        end
      end
    end
  end
end
