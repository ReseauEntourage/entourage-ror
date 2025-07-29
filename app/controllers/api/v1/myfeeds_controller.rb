module Api
  module V1
    class MyfeedsController < FeedsController

      #jcurl "http://localhost:3000/api/v1/myfeeds?page=1&per=100&token=6e06bb0e460145e6a3600bc723072c42&entourage_types=ask_for_help,contribution&status=all&tour_types=medical,social,distributive"
      def index
        feeds = FeedServices::MyFeedFinder.new(
          user: current_user_or_anonymous,
          page: params[:page],
          per: params[:per],
          unread_only: (params[:unread_only].to_s == 'true')
        ).feeds

        render json: ::V1::LegacyFeedSerializer.new(feeds: feeds, user: current_user_or_anonymous, include_last_message: true).to_json, status: 200
      end
    end
  end
end
