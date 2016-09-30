module Api
  module V1
    class MyfeedsController < FeedsController
      #curl "http://localhost:3000/api/v1/myfeeds?page=1&per=2&token=azerty"
      def index
        feeds = FeedServices::FeedFinder.new(user: current_user,
                                             page: params[:page],
                                             per: params[:per],
                                             before: params[:before],
                                             latitude: nil,
                                             longitude: nil,
                                             show_tours: "true",
                                             time_range: time_range,
                                             entourage_types: params[:entourage_types],
                                             tour_types: params[:tour_types],
                                             show_my_entourages_only: "true",
                                             show_my_tours_only: "true",
                                             tour_status: tour_status,
                                             entourage_status: entourage_status,
                                             author: author,
                                             invitee: invitee).feeds
        render json: ::V1::FeedSerializer.new(feeds: feeds, user: current_user, include_last_message: true).to_json, status: 200
      end

      def tour_status
        if params[:status].try(:downcase)=="closed"
          tour_status = ["freezed", "closed"]
        elsif params[:status].try(:downcase)=="all"
          tour_status = nil
        else
          tour_status = ["ongoing"]
        end
        tour_status
      end

      def entourage_status
        if params[:status].try(:downcase)=="closed"
          entourage_status = "closed"
        elsif params[:status].try(:downcase)=="open"
          entourage_status = "open"
        else
          entourage_status = nil
          #here no filter should be applied on status
        end
        entourage_status
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