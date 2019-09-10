module Api
  module V1
    class FeedsController < Api::V1::BaseController
      skip_before_filter :community_warning
      allow_anonymous_access only: [:index, :outings]

      #curl -H "Content-Type: application/json" "https://entourage-back-preprod.herokuapp.com/api/v1/feeds.json?token=azerty"
      def index
        feeds = FeedServices::FeedFinder.new(
          user: current_user_or_anonymous,
          latitude: params[:latitude],
          longitude: params[:longitude],
          types: types,
          show_past_events: params[:show_past_events],
          time_range: time_range,
          distance: params[:distance],
          announcements: params[:announcements],
          page_token: params[:page_token],
          legacy_pagination: legacy_pagination,
          before: params[:before],
        ).feeds

        render json: ::V1::LegacyFeedSerializer.new(feeds: feeds, user: current_user_or_anonymous, base_url: request.base_url, key_infos: api_request.key_infos).to_json, status: 200
      end

      def outings
        outings = FeedServices::OutingsFinder.new(
          user: current_user_or_anonymous,
          latitude: outing_params[:latitude],
          longitude: outing_params[:longitude],
          starting_after: params[:starting_after],
        ).feeds

        render json: ::V1::FeedSerializer.new(feeds: outings, user: current_user_or_anonymous, base_url: request.base_url).to_json, status: 200
      end

      private

      def time_range
        params[:time_range] || 365*24
      end

      def outing_params
        outing_params = params.permit(:latitude, :longitude, :starting_after)
        outing_params.require(:latitude)
        outing_params.require(:longitude)
        outing_params
      end

      def types
        if params.key?(:show_tours) || params.key?(:entourage_types)
          FeedServices::FeedFinder.reformat_legacy_types(params[:entourage_types], params[:show_tours], params[:tour_types])
        else
          params[:types]
        end
      end

      def legacy_pagination
        params.key?(:before)
      end
    end
  end
end
