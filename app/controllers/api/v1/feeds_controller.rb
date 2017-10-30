module Api
  module V1
    class FeedsController < Api::V1::BaseController

      #curl -H "Content-Type: application/json" "https://entourage-back-preprod.herokuapp.com/api/v1/feeds.json?token=azerty"
      def index
        feeds = FeedServices::FeedFinder.new(user: current_user,
                                             page: params[:page],
                                             per: params[:per],
                                             before: params[:before],
                                             latitude: params[:latitude],
                                             longitude: params[:longitude],
                                             show_tours: params[:show_tours],
                                             entourage_types: params[:entourage_types],
                                             tour_types: params[:tour_types],
                                             time_range: time_range,
                                             show_my_entourages_only: params[:show_my_entourages_only],
                                             show_my_tours_only: params[:show_my_tours_only],
                                             show_my_partner_only: params[:show_my_partner_only],
                                             distance: params[:distance],
                                             announcements: params[:announcements]).feeds

        render json: ::V1::FeedSerializer.new(feeds: feeds, user: current_user, base_url: request.base_url).to_json, status: 200
      end

      private

      def time_range
        params[:time_range] || 365*24
      end
    end
  end
end
