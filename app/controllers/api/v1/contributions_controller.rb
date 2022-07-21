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

      def create
        EntourageServices::ContributionBuilder.new(params: contribution_params, user: current_user).create do |on|
          on.success do |contribution|
            render json: contribution, root: :contribution, status: 201, serializer: ::V1::Actions::ContributionSerializer, scope: { user: current_user }
          end

          on.failure do |contribution|
            render json: { message: 'Could not create contribution', reasons: contribution.errors.full_messages }, status: 400
          end
        end
      end

      def update
        return render json: { message: 'unauthorized' }, status: :unauthorized unless @contribution.user == current_user

        EntourageServices::EntourageBuilder.new(params: contribution_params, user: current_user).update(entourage: @contribution) do |on|
          on.success do |contribution|
            render json: contribution, status: 200, serializer: ::V1::Actions::ContributionSerializer, scope: { user: current_user }
          end

          on.failure do |contribution|
            render json: {
              message: 'Could not update contribution', reasons: contribution.errors.full_messages
            }, status: 400
          end
        end
      end

      def destroy
        ContributionServices::Deleter.new(user: current_user, contribution: @contribution).delete do |on|
          on.success do |contribution|
            render json: contribution, root: "user", status: 200, serializer: ::V1::Actions::ContributionSerializer, scope: { user: current_user }
          end

          on.failure do |contribution|
            render json: {
              message: "Could not delete contribution", reasons: contribution.errors.full_messages
            }, status: :bad_request
          end

          on.not_authorized do
            render json: {
              message: "You are not authorized to delete this contribution"
            }, status: :unauthorized
          end
        end
      end

      private

      def set_contribution
        @contribution = Contribution.find(params[:id])
      end

      def index_params
        params.permit(:latitude, :longitude, :travel_distance, :page, :per)
      end

      def contribution_params
        metadata_keys = params.dig(:contribution, :metadata).try(:keys) || []
        params.require(:contribution).permit({
          location: [:longitude, :latitude]
        }, :status, :postal_code, :title, :description, :section, {
          metadata: metadata_keys
        })
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
