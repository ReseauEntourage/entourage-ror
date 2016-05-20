module Api
  module V1
    class FeedsController < Api::V1::BaseController
      def index
        feeds = entourages
        feeds += tours if params[:show_tours]
        feeds = feeds.sort_by { |feed| -feed.created_at.to_i}
        render json: ::V1::FeedSerializer.new(feeds: feeds, user: current_user).to_json, status: 200
      end

      private
      def tours
        TourServices::TourFilterApi.new(user: current_user,
                                        status: nil,
                                        type: params[:tour_types],
                                        vehicle_type: nil,
                                        latitude: params[:latitude],
                                        longitude: params[:longitude],
                                        distance: nil,
                                        page: params[:page],
                                        per: per).tours.to_a
      end

      def entourages
        EntourageServices::EntourageFinder.new(user: current_user,
                                               status: nil,
                                               type: params[:entourage_types],
                                               latitude: params[:latitude],
                                               longitude: params[:longitude],
                                               distance: nil,
                                               show_only_my_entourages: params[:show_only_my_entourages],
                                               page: params[:page],
                                               per: per).entourages.to_a
      end
    end
  end
end