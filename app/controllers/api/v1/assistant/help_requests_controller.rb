module Api
  module V1
    module Assistant
      # Requests for help close to a place.
      class HelpRequestsController < BaseController
        MAX_LIMIT = 20

        def search
          records = finder.find_all.limit(limit).to_a

          render json: { helpRequests: records.map { |action| ::Assistant::Presenters::HelpItem.new(action).as_json } }
        end

        private

        def finder
          ::SolicitationServices::Finder.new(assistant_user, search_params)
        end

        def search_params
          permitted = params.permit(:q, :latitude, :longitude, :section_list, sections: [])
          permitted[:travel_distance] = params[:distance] if params[:distance].present?
          permitted
        end

        def limit
          params[:limit].present? ? params[:limit].to_i.clamp(1, MAX_LIMIT) : 10
        end
      end
    end
  end
end
