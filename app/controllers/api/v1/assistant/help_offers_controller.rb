module Api
  module V1
    module Assistant
      # Offers of help close to a place.
      class HelpOffersController < HelpRequestsController
        def search
          records = ::ContributionServices::Finder.new(assistant_user, search_params).find_all.limit(limit).to_a

          render json: { helpOffers: records.map { |action| ::Assistant::Presenters::HelpItem.new(action).as_json } }
        end
      end
    end
  end
end
