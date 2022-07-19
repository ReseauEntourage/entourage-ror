module Api
  module V1
    class SolicitationsController < Api::V1::BaseController
      before_action :set_solicitation, only: [:show, :update, :destroy, :report]

      after_action :set_last_message_read, only: [:show]

      def index
        render json: SolicitationServices::Finder.new(current_user, index_params).find_all.page(page).per(per), root: :solicitations, each_serializer: ::V1::Actions::SolicitationSerializer, scope: {
          user: current_user
        }
      end

      def show
        render json: @solicitation, serializer: ::V1::Actions::SolicitationHomeSerializer, scope: { user: current_user }
      end

      def create
        EntourageServices::SolicitationBuilder.new(params: solicitation_params, user: current_user).create do |on|
          on.success do |solicitation|
            render json: solicitation, root: :solicitation, status: 201, serializer: ::V1::Actions::SolicitationSerializer, scope: { user: current_user }
          end

          on.failure do |solicitation|
            render json: { message: 'Could not create solicitation', reasons: solicitation.errors.full_messages }, status: 400
          end
        end
      end

      private

      def set_solicitation
        @solicitation = Solicitation.find(params[:id])
      end

      def index_params
        params.permit(:latitude, :longitude, :travel_distance, :page, :per)
      end

      def solicitation_params
        metadata_keys = params.dig(:solicitation, :metadata).try(:keys) || []
        params.require(:solicitation).permit({
          location: [:longitude, :latitude]
        }, :postal_code, :title, :description, {
          metadata: metadata_keys
        }, :recipient_consent_obtained)
      end

      def join_request
        @join_request ||= JoinRequest.where(joinable: @solicitation, user: current_user, status: :accepted).first
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
