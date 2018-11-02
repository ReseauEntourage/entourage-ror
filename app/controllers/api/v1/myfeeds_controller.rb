module Api
  module V1
    class MyfeedsController < FeedsController
      skip_before_filter :community_warning

      #jcurl "http://localhost:3000/api/v1/myfeeds?page=1&per=100&token=6e06bb0e460145e6a3600bc723072c42&entourage_types=ask_for_help,contribution&status=all&tour_types=medical,social,distributive"
      def index
        feeds = FeedServices::FeedFinder.new(context: :myfeed,
                                             user: current_user,
                                             page: params[:page],
                                             per: params[:per],
                                             before: params[:before],
                                             latitude: nil,
                                             longitude: nil,
                                             show_tours: show_tours,
                                             time_range: time_range,
                                             entourage_types: params[:entourage_types],
                                             tour_types: params[:tour_types],
                                             show_my_entourages_only: "true",
                                             show_my_tours_only: "true",
                                             show_my_partner_only: params[:show_my_partner_only],
                                             show_past_events: "true",
                                             tour_status: tour_status,
                                             entourage_status: entourage_status,
                                             author: author,
                                             invitee: invitee,
                                             preload_last_message: true).feeds
        render json: ::V1::LegacyFeedSerializer.new(feeds: feeds, user: current_user, include_last_message: true).to_json, status: 200
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
        elsif params[:status].try(:downcase)=="active"
          entourage_status = "open"
        else
          entourage_status = nil
          #here no filter should be applied on status
        end
        entourage_status
      end

      def show_tours
        params[:show_tours] || "true"
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