module Api
  module V1
    class FeedsController < Api::V1::BaseController
      def index
        feeds = (tours+entourages).sort_by { |feed| feed.created_at}
        render json: ::V1::FeedSerializer.new(feeds: feeds, user: current_user).to_json, status: 200
      end

      private
      def tours
        TourServices::TourFilterApi.new(user: current_user,
                                        status: nil,
                                        type: nil,
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
                                               type: nil,
                                               latitude: params[:latitude],
                                               longitude: params[:longitude],
                                               distance: nil,
                                               page: params[:page],
                                               per: per).entourages.to_a
      end

      def per
        params[:per] || 10
      end
    end
  end
end