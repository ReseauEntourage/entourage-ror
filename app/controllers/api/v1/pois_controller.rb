module Api
  module V1
    class PoisController < Api::V1::BaseController
      attr_writer :member_mailer

      #curl -H "Content-Type: application/json" "https://entourage-back-preprod.herokuapp.com/api/v1/pois.json?token=153ad0b7ef67e5c44b8ef5afc12709e4&category_ids=1,2"
      def index
        @categories = Category.all
        @pois = Poi.validated

        if params[:category_ids].present?
          @pois = @pois.where(category_id: params[:category_ids])
        end

        if params[:latitude].present? and params[:longitude].present?
          @pois = @pois.around params[:latitude], params[:longitude], params[:distance]
        else
          @pois = @pois.limit(25)
        end

        #TODO : refactor API to return 1 top level POI ressources and associated categories ressources
        poi_json = JSON.parse(ActiveModel::ArraySerializer.new(@pois, each_serializer: ::V1::PoiSerializer).to_json)
        categorie_json = JSON.parse(ActiveModel::ArraySerializer.new(@categories, each_serializer: ::V1::CategorySerializer).to_json)
        render json: {pois: poi_json, categories: categorie_json }, status: 200
      end

      def create
        @poi = Poi.new(poi_params)
        @poi.validated = false
        if @poi.save
          render json: @poi, status: 201, serializer: ::V1::PoiSerializer
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
