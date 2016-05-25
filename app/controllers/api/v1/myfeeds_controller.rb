module Api
  module V1
    class MyfeedsController < FeedsController
      def index
        feeds = (entourages+tours).sort_by { |feed| -feed.created_at.to_i}
        render json: ::V1::FeedSerializer.new(feeds: feeds, user: current_user).to_json, status: 200
      end

      private
      def tours
        TourServices::TourFilterApi.new(user: current_user,
                                        status: status,
                                        type: params[:tour_types],
                                        vehicle_type: nil,
                                        latitude: nil,
                                        longitude: nil,
                                        distance: nil,
                                        show_only_my_tours: true,
                                        time_range: params[:time_range],
                                        page: params[:page],
                                        per: per).tours.to_a
      end

      def entourages
        EntourageServices::EntourageFinder.new(user: current_user,
                                               status: status,
                                               type: params[:entourage_types],
                                               latitude: nil,
                                               longitude: nil,
                                               distance: nil,
                                               show_only_my_entourages: true,
                                               time_range: params[:time_range],
                                               page: params[:page],
                                               per: per).entourages.to_a
      end

      def status
        params[:status].try(:downcase)=="closed" ? "closed" : nil
      end
    end
  end
end