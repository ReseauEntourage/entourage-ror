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
        headlines = {
          metadata: { order: [] }
        }

        HomeServices::Headline.new(user: current_user, latitude: params[:latitude], longitude: params[:longitude]).each do |record|
          headlines[:metadata][:order] << record[:name]
          headlines[record[:name]] = {
            type: record[:type],
            data: record[:type] == 'Announcement' ?
              ::V1::AnnouncementSerializer.new(record[:instance], scope: { user: current_user, base_url: request.base_url }, root: false).as_json :
              ::V1::EntourageSerializer.new(record[:instance], {scope: {user: current_user}, root: false}).as_json
          }
        end

        headlines
      end

      def get_outings
        return [] unless params[:latitude] && params[:longitude]

        HomeServices::Outing.new(user: current_user, latitude: params[:latitude], longitude: params[:longitude]).find_all
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
