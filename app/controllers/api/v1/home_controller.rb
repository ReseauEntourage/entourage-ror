module Api
  module V1
    class HomeController < Api::V1::BaseController
      skip_before_action :community_warning

      before_action :set_default_neighborhood, only: [:summary]
      before_action :set_user_recommandations, only: [:summary]
      before_action :clean_inapp_notifications, only: [:summary]

      def index
        render json: {
          metadata: {
            order: metadata_order,
          },

          headlines: Hash.new,

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
            sections: format_sections(Tag.sections),
            interests: format_tags(Tag.interests),
            involvements: format_tags(Tag.involvements),
            concerns: format_tags(Tag.concerns),
            signals: format_tags(Tag.signals),
          },
          reactions: format_reactions(Reaction.all.order(position: :asc)),
          poi_categories: Category.all.map { |category| { id: category.id, name: category.name } }
        }.to_json, status: 200
      end

      def summary
        render json: current_user, serializer: ::V1::Users::SummarySerializer
      end

      private

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

      def format_sections sections
        sections.to_a.map { |t| { id: t.first }.merge(t.last) }
      end

      def format_reactions reactions
        reactions.to_a.map { |reaction| { id: reaction.id, name: reaction.name, key: reaction.key, image_url: reaction.image_url } }
      end

      def set_default_neighborhood
        NeighborhoodServices::Joiner.new(current_user).join_default_neighborhood!
      end

      def set_user_recommandations
        RecommandationServices::User.new(current_user).initiate
      end

      def clean_inapp_notifications
        InappNotificationServices::Builder.new(current_user).skip_obsolete_notifications
      end
    end
  end
end
