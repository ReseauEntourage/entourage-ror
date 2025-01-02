module Api
  module V1
    class SolicitationsController < Api::V1::BaseController
      before_action :set_solicitation, only: [:show, :update, :destroy, :report]
      allow_anonymous_access only: [:report]

      after_action :set_last_message_read, only: [:show]

      def index
        render json: SolicitationServices::Finder.new(current_user, index_params).find_all.page(page).per(per), root: :solicitations, each_serializer: ::V1::ActionSerializer, scope: {
          user: current_user,
          latitude: latitude,
          longitude: longitude
        }
      end

      def show
        render json: @solicitation, serializer: ::V1::ActionSerializer, scope: {
          user: current_user,
          latitude: latitude,
          longitude: longitude
        }
      end

      def create
        EntourageServices::SolicitationBuilder.new(params: solicitation_params, user: current_user).create do |on|
          on.success do |solicitation|
            render json: solicitation, root: :solicitation, status: 201, serializer: ::V1::ActionSerializer, scope: { user: current_user }
          end

          on.failure do |solicitation|
            render json: { message: 'Could not create solicitation', reasons: solicitation.errors.full_messages }, status: 400
          end
        end
      end

      def update
        return render json: { message: 'unauthorized' }, status: :unauthorized unless @solicitation.user == current_user

        EntourageServices::EntourageBuilder.new(params: solicitation_params, user: current_user).update(entourage: @solicitation) do |on|
          on.success do |solicitation|
            render json: solicitation, status: 200, serializer: ::V1::ActionSerializer, scope: { user: current_user }
          end

          on.failure do |solicitation|
            render json: {
              message: 'Could not update solicitation', reasons: solicitation.errors.full_messages
            }, status: 400
          end
        end
      end

      def destroy
        EntourageServices::Deleter.new(user: current_user, entourage: @solicitation).delete(solicitation_destroy_params) do |on|
          on.success do |solicitation|
            render json: solicitation, root: :solicitation, status: 200, serializer: ::V1::ActionSerializer, scope: { user: current_user }
          end

          on.failure do |solicitation|
            render json: {
              message: "Could not delete solicitation", reasons: solicitation.errors.full_messages
            }, status: :bad_request
          end

          on.not_authorized do
            render json: {
              message: "You are not authorized to delete this solicitation"
            }, status: :unauthorized
          end
        end
      end

      def report
        unless report_params[:signals].present?
          render json: {
            code: 'CANNOT_REPORT_DONATION',
            message: 'signals is required'
          }, status: :bad_request and return
        end

        SlackServices::SignalSolicitation.new(
          solicitation: @solicitation,
          reporting_user: current_user,
          signals: report_params[:signals],
          message: report_params[:message]
        ).notify

        head :created
      end

      private

      def set_solicitation
        @solicitation = Solicitation.find_by_id_through_context(params[:id], params)

        render json: { message: 'Could not find solicitation' }, status: 400 unless @solicitation.present?
      end

      def index_params
        params.permit(:q, :latitude, :longitude, :travel_distance, :section_list, sections: [])
      end

      def solicitation_params
        metadata_keys = params.dig(:solicitation, :metadata).try(:keys) || []
        params.require(:solicitation).permit({
          location: [:longitude, :latitude]
        }, :postal_code, :title, :description, :section, :auto_post_at_create, {
          metadata: metadata_keys
        }, :recipient_consent_obtained)
      end

      def solicitation_destroy_params
        params.require(:solicitation).permit([:close_message, :outcome])
      end

      def join_request
        @join_request ||= JoinRequest.where(joinable: @solicitation, user: current_user, status: :accepted).first
      end

      def set_last_message_read
        return unless join_request

        join_request.set_chat_messages_as_read
      end

      def page
        params[:page] || 1
      end

      def latitude
        params[:latitude] || current_user.latitude
      end

      def longitude
        params[:longitude] || current_user.longitude
      end

      def report_params
        params.require(:report).permit(:message, signals: [])
      end
    end
  end
end
