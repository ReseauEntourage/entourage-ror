module Api
  module V1
    class ContributionsController < Api::V1::BaseController
      before_action :set_contribution, only: [:show, :update, :destroy, :report]
      before_action :authorised?, only: [:update, :destroy]
      allow_anonymous_access only: [:report]

      after_action :set_last_message_read, only: [:show]

      def index
        render json: ContributionServices::Finder.new(current_user, index_params).find_all.page(page).per(per), root: :contributions, each_serializer: ::V1::ActionSerializer, scope: {
          user: current_user,
          latitude: latitude,
          longitude: longitude
        }
      end

      def show
        render json: @contribution, serializer: ::V1::ActionSerializer, scope: {
          user: current_user,
          latitude: latitude,
          longitude: longitude
        }
      end

      def create
        EntourageServices::ContributionBuilder.new(params: contribution_params, user: current_user).create do |on|
          on.success do |contribution|
            render json: contribution, root: :contribution, status: 201, serializer: ::V1::ActionSerializer, scope: { user: current_user }
          end

          on.failure do |contribution|
            render json: { message: 'Could not create contribution', reasons: contribution.errors.full_messages }, status: 400
          end
        end
      end

      def update
        EntourageServices::EntourageBuilder.new(params: contribution_params, user: current_user).update(entourage: @contribution) do |on|
          on.success do |contribution|
            render json: contribution, status: 200, serializer: ::V1::ActionSerializer, scope: { user: current_user }
          end

          on.failure do |contribution|
            render json: {
              message: 'Could not update contribution', reasons: contribution.errors.full_messages
            }, status: 400
          end
        end
      end

      def destroy
        ContributionServices::Deleter.new(user: current_user, contribution: @contribution).delete(contribution_destroy_params) do |on|
          on.success do |contribution|
            render json: contribution, root: :contribution, status: 200, serializer: ::V1::ActionSerializer, scope: { user: current_user }
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

      def report
        unless report_params[:signals].present?
          render json: {
            code: 'CANNOT_REPORT_DONATION',
            message: 'signals is required'
          }, status: :bad_request and return
        end

        SlackServices::SignalContribution.new(
          contribution: @contribution,
          reporting_user: current_user,
          signals: report_params[:signals],
          message: report_params[:message]
        ).notify

        head :created
      end

      def presigned_upload
        allowed_types = Contribution::CONTENT_TYPES

        unless params[:content_type].in? allowed_types
          type_list = allowed_types.to_sentence(two_words_connector: ' or ', last_word_connector: ', or ')
          return render_error(code: "INVALID_CONTENT_TYPE", message: "Content-Type must be #{type_list}.", status: 400)
        end

        extension = MiniMime.lookup_by_content_type(params[:content_type]).extension
        key = "#{SecureRandom.uuid}.#{extension}"
        url = Contribution.presigned_url(key, params[:content_type])

        render json: { upload_key: key, presigned_url: url }
      end

      private

      def set_contribution
        @contribution = Contribution.find(params[:id])
      end

      def index_params
        params.permit(:latitude, :longitude, :travel_distance, :page, :per, sections: [])
      end

      def contribution_params
        metadata_keys = params.dig(:contribution, :metadata).try(:keys) || []
        params.require(:contribution).permit({
          location: [:longitude, :latitude]
        }, :postal_code, :title, :description, :section, {
          metadata: metadata_keys
        }, :image_url)
      end

      def contribution_destroy_params
        params.require(:contribution).permit([:close_message, :outcome])
      end

      def report_params
        params.require(:report).permit(:message, signals: [])
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

      def latitude
        params[:latitude] || current_user.latitude
      end

      def longitude
        params[:longitude] || current_user.longitude
      end

      def authorised?
        unless @contribution.user == current_user
          render json: { message: 'unauthorized user' }, status: :unauthorized
        end
      end
    end
  end
end
