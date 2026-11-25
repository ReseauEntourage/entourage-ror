module Api
  module V1
    module Assistant
      # Requests for help close to a place.
      class HelpRequestsController < BaseController
        LIMIT = 10

        def search
          finder_params = search_params
          return if finder_params.nil?

          records = finder_for(finder_params).find_all.limit(LIMIT).to_a
          render json: { items: records.map { |action| ::Assistant::Presenters::HelpItem.new(action).as_json } }
        end

        private

        def finder_for params
          ::SolicitationServices::Finder.new(assistant_user, params)
        end

        def search_params
          coordinates = coordinates_for_city(params[:city])
          return if coordinates.nil?

          ActionController::Parameters.new({ section_list: params[:category].to_s.presence }.merge(coordinates)).permit!
        end
      end
    end
  end
end
