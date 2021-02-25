module Api
  module V1
    class HomeController < Api::V1::BaseController
      skip_before_filter :community_warning

      def index
        # per is defined in BaseController
        page = params[:page] || 1

        announcements = FeedServices::AnnouncementsService.announcements_for_user(current_user)

        if params[:latitude] && params[:longitude]
          outings = FeedServices::OutingsFinder.new(
            user: current_user,
            latitude: params[:latitude],
            longitude: params[:longitude],
            starting_after: params[:starting_after]
          ).feeds
        else
          outings = []
        end

        entourages = EntourageServices::EntourageFinder.new(
          user: current_user,
          types: params[:types] || params[:entourage_types],
          latitude: params[:latitude],
          longitude: params[:longitude],
          distance: params[:distance],
          page: page,
          per: per,
          show_past_events: params[:show_past_events],
          time_range: params[:time_range],
          before: params[:before],
          partners_only: params[:partners_only],
          no_outings: true
        ).entourages

        if current_user.public?
          tours = []
        else
          tours = TourServices::TourFilterApi.new(
            user: current_user,
            status: params[:status],
            type: params[:type] || params[:tour_type],
            vehicle_type: params[:vehicle_type],
            latitude: params[:latitude],
            longitude: params[:longitude],
            distance: params[:distance],
            page: page,
            per: per
          ).tours
        end

        render json: {
          metadata: {
            order: [:announcements, :outings, :entourages, :tours],
          },

          announcements: ::ActiveModel::ArraySerializer.new(
            announcements,
            each_serializer: ::V1::AnnouncementSerializer,
            scope: { user: current_user, base_url: request.base_url }
          ),

          outings: ::ActiveModel::ArraySerializer.new(
            outings.map(&:feedable), # requires OutingsFinder refactor on Object mapping
            each_serializer: ::V1::EntourageSerializer,
            scope: { user: current_user }
          ),

          entourages: ::ActiveModel::ArraySerializer.new(
            entourages,
            each_serializer: ::V1::EntourageSerializer,
            scope: { user: current_user }
          ),

          tours: ::ActiveModel::ArraySerializer.new(
            tours,
            each_serializer: ::V1::TourSerializer,
            scope: { user: current_user }
          )
        }.to_json, status: 200
      end
    end
  end
end
