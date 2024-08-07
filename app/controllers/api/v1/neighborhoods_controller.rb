module Api
  module V1
    class NeighborhoodsController < Api::V1::BaseController
      before_action :set_neighborhood, only: [:show, :update, :destroy, :report]

      after_action :set_last_message_read, only: [:show]

      def index
        render json: NeighborhoodServices::Finder.new(current_user, index_params).find_all
          .includes(:translation, :image_resize_actions, :user)
          .page(page)
          .per(per), root: :neighborhoods, each_serializer: ::V1::Neighborhoods::NotMemberListSerializer, scope: { user: current_user }
      end

      def default
        return render json: {} unless @neighborhood = default_neighborhood_as_member

        render json: @neighborhood, serializer: ::V1::NeighborhoodHomeSerializer, scope: { user: current_user }
      end

      def show
        render json: @neighborhood, serializer: ::V1::NeighborhoodHomeSerializer, scope: { user: current_user }
      end

      def create
        @neighborhood = Neighborhood.new(neighborhood_params)
        @neighborhood.user = current_user

        if @neighborhood.save
          render json: @neighborhood, status: 201, serializer: ::V1::NeighborhoodSerializer, scope: { user: current_user }
        else
          render json: { message: "Could not create Neighborhood", reasons: @neighborhood.errors.full_messages }, status: 400
        end
      end

      def update
        return render json: { message: 'unauthorized' }, status: :unauthorized if @neighborhood.user != current_user

        @neighborhood.assign_attributes(neighborhood_update_params)

        if @neighborhood.save
          render json: @neighborhood, status: 200, serializer: ::V1::NeighborhoodSerializer, scope: { user: current_user }
        else
          render json: {
            message: 'Could not update neighborhood', reasons: @neighborhood.errors.full_messages
          }, status: 400
        end
      end

      def joined
        render json: Neighborhood.joined_by(current_user).page(page).per(per), root: :neighborhoods, each_serializer: ::V1::NeighborhoodSerializer, scope: { user: current_user }
      end

      def destroy
        NeighborhoodServices::Deleter.new(user: current_user, neighborhood: @neighborhood).delete do |on|
          on.success do |neighborhood|
            render json: neighborhood, root: "user", status: 200, serializer: ::V1::NeighborhoodSerializer, scope: { user: current_user }
          end

          on.failure do |neighborhood|
            render json: {
              message: "Could not delete neighborhood", reasons: neighborhood.errors.full_messages
            }, status: :bad_request
          end

          on.not_authorized do
            render json: {
              message: "You are not authorized to delete this neighborhood"
            }, status: :unauthorized
          end
        end
      end

      def report
        unless report_params[:signals].present?
          render json: {
            code: 'CANNOT_REPORT_NEIGHBORHOOD',
            message: 'signals is required'
          }, status: :bad_request and return
        end

        SlackServices::SignalNeighborhood.new(
          neighborhood: @neighborhood,
          reporting_user: current_user,
          signals: report_params[:signals],
          message: report_params[:message]
        ).notify

        head :created
      end

      private

      def set_neighborhood
        @neighborhood = Neighborhood.find_by_id_through_context(params[:id], params)

        render json: { message: 'Could not find neighborhood' }, status: 400 unless @neighborhood.present?
      end

      def index_params
        params.permit(:q, :latitude, :longitude, :travel_distance, :interest_list, interests: [])
      end

      def neighborhood_params
        params.require(:neighborhood).permit(:name, :description, :welcome_message, :ethics, :latitude, :longitude, :google_place_id, :place_name, :display_address, :neighborhood_image_id, :other_interest, interests: [])
      end

      def neighborhood_update_params
        neighborhood_params.except(:other_interest)
      end

      def join_request
        @join_request ||= JoinRequest.where(joinable: @neighborhood, user: current_user, status: :accepted).first
      end

      def set_last_message_read
        return unless join_request

        join_request.set_chat_messages_as_read
      end

      def page
        params[:page] || 1
      end

      def report_params
        params.require(:report).permit(:message, signals: [])
      end

      def default_neighborhood_as_member
        @default_neighborhood_as_member ||= NeighborhoodServices::Joiner.new(current_user).default_neighborhood_as_member
      end
    end
  end
end
