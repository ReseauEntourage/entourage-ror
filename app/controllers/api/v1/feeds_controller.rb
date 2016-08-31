module Api
  module V1
    class FeedsController < Api::V1::BaseController

      #curl -H "Content-Type: application/json" "https://entourage-back-preprod.herokuapp.com/api/v1/feeds.json?token=azerty"
      def index
        feeds = FeedServices::FeedFinder.new(user: current_user,
                                             page: params[:page],
                                             per: params[:per],
                                             before: params[:before]).feeds
        render json: ::V1::FeedSerializer.new(feeds: feeds, user: current_user).to_json, status: 200
        # feeds = entourages
        # feeds += tours if params[:show_tours]=="true" && current_user.pro?
        # feeds = feeds.sort_by { |feed| -feed.updated_at.to_i}
        # render json: ::V1::FeedSerializer.new(feeds: feeds, user: current_user).to_json, status: 200
      end

      private
      def tours
        TourServices::TourFilterApi.new(user: current_user,
                                        status: nil,
                                        type: params[:tour_types],
                                        vehicle_type: nil,
                                        show_only_my_tours: params[:show_my_entourages_only]=="true",
                                        latitude: params[:latitude],
                                        longitude: params[:longitude],
                                        distance: nil,
                                        time_range: params[:time_range],
                                        page: params[:page],
                                        per: params[:per],
                                        before: params[:before]).tours.to_a
      end

      def entourages
        EntourageServices::EntourageFinder.new(user: current_user,
                                               status: nil,
                                               type: params[:entourage_types],
                                               latitude: params[:latitude],
                                               longitude: params[:longitude],
                                               distance: nil,
                                               show_my_entourages_only: params[:show_my_entourages_only]=="true",
                                               time_range: params[:time_range],
                                               page: params[:page],
                                               per: params[:per],
                                               before: params[:before]).entourages.to_a
      end
    end
  end
end