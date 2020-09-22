module Api
  module V1
    class PoisController < Api::V1::BaseController
      skip_before_filter :authenticate_user!, only: :index

      attr_writer :member_mailer

      #curl -H "Content-Type: application/json" "https://entourage-back-preprod.herokuapp.com/api/v1/pois.json?token=153ad0b7ef67e5c44b8ef5afc12709e4&category_ids=1,2"
      def index
        @categories = Category.all
        @pois = Poi.validated

        version = params[:v] == '2' ? :v2 : :v1

        if params[:category_ids].present?
          categories = params[:category_ids].split(",").map(&:to_i).uniq
          category_count = categories.count
          if version == :v1
            @pois = @pois.where(category_id: categories)
          else
            @pois = @pois.joins(:pois_categories).where(categories_pois: {category_id: categories})
          end
        else
          category_count = @categories.count
        end

        # distance was calculated incorrectly on Android before 3.6.0
        key_infos = api_request.key_infos || {}
        if key_infos[:device] == 'Android' && ApplicationKey::Version.new(key_infos[:version]) < '3.6.0'
          params[:distance] = params[:distance].to_f * 2
        end

        if params[:latitude].present? and params[:longitude].present?

          min_distance =
            if category_count <= 2
              5
            else
              2
            end

          if params[:distance]
            distance = params[:distance].to_f / 2
            distance = min_distance if distance < min_distance
          else
            distance = nil
          end

          @pois = @pois.around params[:latitude], params[:longitude], distance

          partners_filters = (params[:partners_filters] || "").split(",").compact.uniq.map(&:to_sym) & [:donations, :volunteers]
          if partners_filters.any?
            @pois = @pois.joins("left join partners on partners.id = partner_id")
            clauses = ["partner_id is null"]
            clauses << "donations_needs is not null"  if partners_filters.include?(:donations)
            clauses << "volunteers_needs is not null" if partners_filters.include?(:volunteers)
            @pois = @pois.where(clauses.join(" OR "))
          end

          @pois = @pois
            .order(PostgisHelper.distance_from(params[:latitude], params[:longitude], :pois))
        else
          @pois = @pois.limit(25)
        end

        #TODO : refactor API to return 1 top level POI ressources and associated categories ressources
        poi_json = PoiServices::PoiOptimizedSerializer.new(@pois, box_size: params[:distance], version: version) do |pois|
          if version == :v1
            # manually preload the :category association to prevent n+1 queries
            category_by_id = Hash[@categories.map { |c| [c.id, c] }]
            pois.each { |p| p.category = category_by_id[p.category_id] }
          end

          ActiveModel::ArraySerializer.new(pois, each_serializer: ::V1::PoiSerializer, scope: {version: :"#{version}_list"}).as_json
        end.serialize

        payload =
          case version
          when :v1
            categorie_json = ActiveModel::ArraySerializer.new(@categories, each_serializer: ::V1::CategorySerializer).as_json
            {pois: poi_json, categories: categorie_json}
          when :v2
            {pois: poi_json}
          end
        render json: payload, status: 200
      end

      def show
        poi = Poi.validated.find(params[:id])
        render json: poi, serializer: ::V1::PoiSerializer, scope: {version: :v2}
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
