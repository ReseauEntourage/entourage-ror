module Api
  module V1
    class HomeController < Api::V1::BaseController
      skip_before_filter :community_warning

      def index
        render json: {
          metadata: {
            order: [:headlines, :outings, :entourages],
          },

          headlines: get_headlines,

          outings: ::ActiveModel::ArraySerializer.new(
            get_outings,
            each_serializer: ::V1::EntourageSerializer,
            scope: { user: current_user }
          ),

          entourages: ::ActiveModel::ArraySerializer.new(
            get_entourages,
            each_serializer: ::V1::EntourageSerializer,
            scope: { user: current_user }
          )
        }.to_json, status: 200
      end

      private

      def get_headlines
        pin_1 = get_entourages.first
        pin_2 = get_entourages.second
        announcement_1 = get_announcements.first
        announcement_2 = get_announcements.second
        entourage = get_entourages.third

        {
          metadata: {
            order: [:pin_1, :announcement_1, :entourage, :pin_2, :announcement_2],
          },
          pin_1: {
            type: 'Entourage',
            data: ::V1::EntourageSerializer.new(pin_1, {scope: {user: current_user}, root: false}).as_json,
          },
          pin_2: {
            type: 'Entourage',
            data: ::V1::EntourageSerializer.new(pin_2, {scope: {user: current_user}, root: false}).as_json,
          },
          announcement_1: {
            type: 'Announcement',
            data: ::V1::AnnouncementSerializer.new(announcement_1, scope: { user: current_user, base_url: request.base_url }, root: false).as_json,
          },
          announcement_2: {
            type: 'Announcement',
            data: ::V1::AnnouncementSerializer.new(announcement_2, scope: { user: current_user, base_url: request.base_url }, root: false).as_json,
          },
          entourage: {
            type: 'Entourage',
            data: ::V1::EntourageSerializer.new(entourage, {scope: {user: current_user}, root: false}).as_json,
          }
        }
      end

      def get_announcements
        FeedServices::AnnouncementsService.announcements_for_user(current_user)[0..1]
      end

      def get_outings
        return [] unless params[:latitude] && params[:longitude]

        FeedServices::OutingsFinder.new(
          user: current_user,
          latitude: params[:latitude],
          longitude: params[:longitude]
        ).feeds.map(&:feedable)
      end

      def get_entourages
        EntourageServices::EntourageFinder.new(
          user: current_user,
          latitude: params[:latitude],
          longitude: params[:longitude],
          page: params[:page],
          per: per,
          no_outings: true
        ).entourages
      end
    end
  end
end
