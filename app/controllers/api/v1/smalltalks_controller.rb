module Api
  module V1
    class SmalltalksController < Api::V1::BaseController
      before_action :set_smalltalk, only: [:show, :update, :destroy]
      before_action :ensure_is_member, only: [:show]

      def index
        @smalltalks = Smalltalk.joins(:members)
          .includes(:chat_messages)
          .where('join_requests.user_id = ?', current_user.id)
          .merge(JoinRequest.accepted)
          .page(page)
          .per(per)

        render json: @smalltalks, root: :smalltalks, each_serializer: ::V1::SmalltalkSerializer, scope: { user: current_user }
      end

      def show
        render json: @smalltalk, serializer: ::V1::SmalltalkSerializer, scope: { user: current_user }
      end

      private

      def set_smalltalk
        @smalltalk = Smalltalk.find_by_id_through_context(params[:id], params)

        render json: { message: 'Could not find smalltalk' }, status: 400 unless @smalltalk.present?
      end

      def page
        params[:page] || 1
      end

      def ensure_is_member
        render json: { message: 'unauthorized user' }, status: :unauthorized unless join_request
      end

      def join_request
        @join_request ||= JoinRequest.where(joinable: @smalltalk, user: @current_user, status: :accepted).first
      end
    end
  end
end
