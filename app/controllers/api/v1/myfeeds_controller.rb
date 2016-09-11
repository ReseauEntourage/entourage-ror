module Api
  module V1
    class MyfeedsController < FeedsController
      #curl "http://localhost:3000/api/v1/myfeeds?page=1&per=2"
      def index
        feeds = FeedServices::FeedFinder.new(user: current_user,
                                             page: params[:page],
                                             per: params[:per],
                                             before: params[:before],
                                             show_tours: "true",
                                             entourage_types: params[:entourage_types],
                                             tour_types: params[:tour_types],
                                             show_my_entourages_only: "true",
                                             show_my_tours_only: "true",
                                             tour_status: tour_status,
                                             entourage_status: entourage_status,
                                             author: author,
                                             invitee: invitee).feeds
        render json: ::V1::FeedSerializer.new(feeds: feeds, user: current_user, include_last_message: true).to_json, status: 200
        # feeds = (entourages+tours).sort_by { |feed| -feed.created_at.to_i}
        # render json: ::V1::FeedSerializer.new(feeds: feeds, user: current_user, include_last_message: true).to_json, status: 200
      end

      private
      def tours
        TourServices::TourFilterApi.new(user: current_user,
                                        status: tour_status,
                                        type: params[:tour_types],
                                        vehicle_type: nil,
                                        latitude: nil,
                                        longitude: nil,
                                        distance: nil,
                                        show_only_my_tours: true,
                                        time_range: time_range,
                                        page: params[:page],
                                        per: per,
                                        author: author,
                                        invitee: invitee).tours.to_a
      end

      def entourages
        EntourageServices::EntourageFinder.new(user: current_user,
                                               status: entourage_status,
                                               type: params[:entourage_types],
                                               latitude: nil,
                                               longitude: nil,
                                               distance: nil,
                                               show_my_entourages_only: true,
                                               time_range: time_range,
                                               page: params[:page],
                                               per: per,
                                               author: author,
                                               invitee: invitee).entourages.to_a
      end

      def tour_status
        params[:status].try(:downcase)=="closed" ? ["freezed"] : ["ongoing", "closed"]
      end

      def entourage_status
        params[:status].try(:downcase)=="closed" ? "closed" : "open"
      end

      def time_range
        params[:time_range] || 365*24
      end

      def author
        current_user if params[:created_by_me] == "true"
      end

      def invitee
        current_user if params[:accepted_invitation] == "true"
      end
    end
  end
end