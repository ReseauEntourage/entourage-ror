module Api
  module V1
    class ContributionsController < Api::V1::BaseController
      before_action :set_contribution, only: [:show, :update, :destroy, :report]

      after_action :set_last_message_read, only: [:show]

      def index
        render json: ContributionServices::Finder.new(current_user, index_params).find_all.page(page).per(per), root: :contributions, each_serializer: ::V1::Actions::ContributionSerializer, scope: {
          user: current_user
        }
      end

      def show
        render json: @contribution, serializer: ::V1::Actions::ContributionHomeSerializer, scope: { user: current_user }
      end

      private

      def set_contribution
        @contribution = Contribution.find(params[:id])
      end

      def index_params
        params.permit(:latitude, :longitude, :travel_distance, :page, :per)
      end

      def join_request
        @join_request ||= JoinRequest.where(joinable: @contribution, user: current_user, status: :accepted).first
      end

      def set_last_message_read
        return unless join_request

        join_request.update(last_message_read: Time.now)
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
