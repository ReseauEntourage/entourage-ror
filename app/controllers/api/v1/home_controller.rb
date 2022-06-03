module Api
  module V1
    class HomeController < Api::V1::BaseController
      skip_before_action :community_warning

      def index
        render json: {
          metadata: {
            order: metadata_order,
          },

          headlines: get_headlines,

          outings: ActiveModel::Serializer::CollectionSerializer.new(
            get_outings,
            serializer: ::V1::EntourageSerializer,
            scope: { user: current_user }
          ),

          entourages: ActiveModel::Serializer::CollectionSerializer.new(
            entourages([:contribution, :ask_for_help]),
            serializer: ::V1::EntourageSerializer,
            scope: { user: current_user }
          ),

          entourage_contributions: ActiveModel::Serializer::CollectionSerializer.new(
            entourages(:contribution),
            serializer: ::V1::EntourageSerializer,
            scope: { user: current_user }
          ),

          entourage_ask_for_helps: ActiveModel::Serializer::CollectionSerializer.new(
            entourages(:ask_for_help),
            serializer: ::V1::EntourageSerializer,
            scope: { user: current_user }
          )
        }.to_json, status: 200
      end

      def metadata
        render json: {
          tags: {
            interests: format_tags(Tag.interests),
            signals: format_tags(Tag.signals)
          }
        }.to_json, status: 200
      end

      def summary
        render json: current_user, serializer: ::V1::Users::SummarySerializer
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
              ::V1::AnnouncementSerializer.new(record[:instance], scope: { user: current_user, base_url: request.base_url, portrait: true }, root: false).as_json :
              ::V1::EntourageSerializer.new(record[:instance], {scope: {user: current_user}, root: false}).as_json
          }
        end

        headlines
      end

      def get_outings
        return [] unless params[:latitude] && params[:longitude]

        HomeServices::Outing.new(user: current_user, latitude: params[:latitude], longitude: params[:longitude]).find_all
      end

      def entourages entourage_type
        HomeServices::Action.new(user: current_user, latitude: params[:latitude], longitude: params[:longitude]).find_all(entourage_type: entourage_type)
      end

      def metadata_order
        return [:headlines, :outings, :entourages] unless params[:split_entourages].present?

        if current_user.is_ask_for_help?
          [:headlines, :outings, :entourage_contributions, :entourage_ask_for_helps]
        else
          [:headlines, :outings, :entourage_ask_for_helps, :entourage_contributions]
        end
      end

      def format_tags tags
        tags.to_a.map { |t| { id: t.first, name: t.last } }
      end
    end
  end
end
