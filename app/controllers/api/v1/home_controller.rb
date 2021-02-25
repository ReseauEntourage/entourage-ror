module Api
  module V1
    class HomeController < Api::V1::BaseController
      skip_before_filter :community_warning

      def index
        render json: {
          metadata: {
            order: [:announcements, :outings, :entourages, :tours],
          },

          announcements: ::ActiveModel::ArraySerializer.new(
            get_announcements,
            each_serializer: ::V1::AnnouncementSerializer,
            scope: { user: current_user, base_url: request.base_url }
          ),

          outings: ::ActiveModel::ArraySerializer.new(
            get_outings,
            each_serializer: ::V1::EntourageSerializer,
            scope: { user: current_user }
          ),

          entourages: ::ActiveModel::ArraySerializer.new(
            get_entourages,
            each_serializer: ::V1::EntourageSerializer,
            scope: { user: current_user }
          ),

          tours: ::ActiveModel::ArraySerializer.new(
            get_tours,
            each_serializer: ::V1::TourSerializer,
            scope: { user: current_user }
          )
        }.to_json, status: 200
      end

      private

      def get_announcements
        FeedServices::AnnouncementsService.announcements_for_user(current_user)
      end

      def get_outings
        return [] unless params[:latitude] && params[:longitude]

        FeedServices::OutingsFinder.new(
          user: current_user,
          latitude: params[:latitude],
          longitude: params[:longitude],
          starting_after: params[:starting_after]
        ).feeds.map(&:feedable)
      end

      def get_entourages
        EntourageServices::EntourageFinder.new(
          user: current_user,
          types: params[:types] || params[:entourage_types],
          latitude: params[:latitude],
          longitude: params[:longitude],
          distance: params[:distance],
          page: params[:page],
          per: per,
          show_past_events: params[:show_past_events],
          time_range: params[:time_range],
          before: params[:before],
          partners_only: params[:partners_only],
          no_outings: true
        ).entourages
      end

      def get_tours
        return [] if current_user.public?

        TourServices::TourFilterApi.new(
          user: current_user,
          status: params[:status],
          type: params[:type] || params[:tour_type],
          vehicle_type: params[:vehicle_type],
          latitude: params[:latitude],
          longitude: params[:longitude],
          distance: params[:distance],
          page: params[:page],
          per: per
        ).tours
      end
    end
  end
end
