module Api
  module V1
    class FeedsController < Api::V1::BaseController

      #curl -H "Content-Type: application/json" "https://entourage-back-preprod.herokuapp.com/api/v1/feeds.json?token=azerty"
      def index
        feeds = FeedServices::FeedFinder.new(user: current_user,
                                             page: params[:page],
                                             per: params[:per],
                                             before: params[:before],
                                             show_tours: params[:show_tours],
                                             entourage_types: params[:entourage_types],
                                             tour_types: params[:tour_types],
                                             show_my_entourages_only: params[:show_my_entourages_only],
                                             show_my_tours_only: params[:show_my_tours_only]).feeds
        render json: ::V1::FeedSerializer.new(feeds: feeds, user: current_user).to_json, status: 200
        # feeds = entourages
        # feeds += tours if params[:show_tours]=="true" && current_user.pro?
        # feeds = feeds.sort_by { |feed| -feed.updated_at.to_i}
        # render json: ::V1::FeedSerializer.new(feeds: feeds, user: current_user).to_json, status: 200
      end
    end
  end
end