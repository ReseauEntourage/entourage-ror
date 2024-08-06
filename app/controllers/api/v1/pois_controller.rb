module Api
  module V1
    class PoisController < Api::V1::BaseController
      skip_before_action :authenticate_user!, only: [:index, :show, :create]

      before_action :validate_form_signature, only: [:create]
      after_action :soliguide_search_ping!, only: [:index, :clusters]

      attr_writer :member_mailer

      #curl -H "Content-Type: application/json" "https://entourage-back-preprod.herokuapp.com/api/v1/pois.json?token=153ad0b7ef67e5c44b8ef5afc12709e4&category_ids=1,2"
      def index
        version = params[:v] == '2' ? :v2 : :v1

        @categories = Category.all

        @pois = Poi.validated
          .text_search(params[:query])
          .with_category_ids(category_ids)
          .around(coordinates[:latitude], coordinates[:longitude], distance)
          .with_partners_filters(partners_filters)
          .order(Arel.sql('random()')).limit(100)

        #TODO : refactor API to return 1 top level POI ressources and associated categories ressources
        poi_json = PoiServices::PoiOptimizedSerializer.new(@pois, box_size: params[:distance], version: version) do |pois|
          if version == :v1
            # manually preload the :category association to prevent n+1 queries
            category_by_id = Hash[@categories.map { |c| [c.id, c] }]
            pois.each { |p| p.category = category_by_id[p.category_id] }
          end

          ActiveModel::Serializer::CollectionSerializer.new(pois, serializer: ::V1::PoiSerializer, scope: {version: :"#{version}_list"}).as_json
        end.serialize

        payload = { pois: poi_json }
        payload.merge!({ categories: Category.all.map { |category| { id: category.id, name: category.name } } }) if version == :v1

        render json: payload, status: 200
      end

      def clusters
        render json:
          Poi.validated
            .with_partners_filters(partners_filters)
            .clustered(coordinates[:latitude], coordinates[:longitude], distance)
            .text_search(params[:query])
            .with_category_ids(category_ids),
          root: :clusters,
          each_serializer: ::V1::ClusterSerializer,
          status: 200
      end

      def show
        if params[:id].start_with?('s') && current_user && current_user.not_default_lang?
          return render json: { poi: PoiServices::SoliguideShow.get(params[:id][1..], current_user.lang) }
        end

        if params[:id].start_with?('s')
          AsyncService.new(PoiServices::SoliguideShow).get(params[:id][1..])
        end

        poi = Poi.validated.find_by_uuid(params[:id])
        render json: poi, serializer: ::V1::PoiSerializer, scope: {version: :v2}
      end

      def create
        @poi = Poi.new(poi_params)
        @poi = PoiServices::PoiGeocoder.new(poi: @poi, params: poi_params).geocode
        @poi.category = Category.order(:id).first unless @poi.category
        @poi.validated = false

        # TODO make this cleaner
        @poi.categories << @poi.category

        if @poi.save
          render json: @poi, status: 201, serializer: ::V1::PoiSerializer, scope: { version: :v2 }
        else
          render json: { message: "Could not create POI", reasons: @poi.errors.full_messages }, status: 400
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
        PoiServices::Typeform.convert_params(
          params.require(:form_response)
        )
      end

      def soliguide_params
        params.permit(:latitude, :longitude, :distance, :category_ids, :query)
      end

      def soliguide_search_ping!
        # we send this request just for Soliguide stats; Soliguide POIs have already been added from Entourage DB
        soliguide = PoiServices::Soliguide.new(soliguide_params)

        AsyncService.new(PoiServices::SoliguideIndex).post_only_query(soliguide.query_params) if soliguide.apply?
      end

      def coordinates
        return {
          latitude: params[:latitude],
          longitude: params[:longitude]
        } if params[:latitude] && params[:longitude]

        return { latitude: current_user.latitude, longitude: current_user.longitude } if current_user.present?

        Hash.new
      end

      def distance
        params[:distance] || current_user&.travel_distance || 1
      end

      def category_ids
        @category_ids ||= (params[:category_ids] || "").split(",").map(&:to_i).uniq
      end

      def partners_filters
        @partners_filters ||= (params[:partners_filters] || "").split(",").compact.uniq.map(&:to_sym) & [:donations, :volunteers]
      end

      def member_mailer
        @member_mailer ||= MemberMailer
      end

      def show_params
        params.permit([:id, :action, :controller, :token])
      end

      def validate_form_signature
        render json: { message: 'unauthorized' }, status: :unauthorized unless PoiServices::Typeform.new(request).verify
      end
    end
  end
end
