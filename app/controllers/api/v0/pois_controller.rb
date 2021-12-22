module Api
  module V0
    class PoisController < Api::V0::BaseController
      attr_writer :member_mailer

      def index
        @categories = Category.all
        @pois = Poi.validated
        if params[:latitude].present? and params[:longitude].present?
          @pois = @pois.around params[:latitude], params[:longitude], params[:distance]
        else
          @pois = @pois.limit(25)
        end

        #TODO : refactor API to return 1 top level POI ressources and associated categories ressources
        poi_json = JSON.parse(ActiveModel::Serializer::CollectionSerializer.new(@pois, serializer: ::V0::PoiSerializer).to_json)
        categorie_json = JSON.parse(ActiveModel::Serializer::CollectionSerializer.new(@categories, serializer: ::V0::CategorySerializer).to_json)
        render json: {pois: poi_json, categories: categorie_json }, status: 200
      end

      def create
        @poi = Poi.new(poi_params)
        @poi.validated = false
        if @poi.save
          render json: @poi, status: 201, serializer: ::V0::PoiSerializer
        else
          render json: {message: "Could not create POI", reasons: @poi.errors.full_message }, status: 400
        end
      end

      def report
        poi = Poi.find_by(id: params[:id])
        if poi.nil?
          head '404'
        else
          message = params[:message]
          if message.nil?
            render json: {message: "Missing 'message' params"}, status: 400
          else
            member_mailer.poi_report(poi, @current_user, message).deliver_later
            render json: {message: message}, status: 201
          end
        end
      end

      private

      def poi_params
        params.require(:poi).permit(:name, :latitude, :longitude, :adress, :phone, :website, :email, :audience, :category_id)
      end

      def member_mailer
        @member_mailer ||= MemberMailer
      end
    end
  end
end
