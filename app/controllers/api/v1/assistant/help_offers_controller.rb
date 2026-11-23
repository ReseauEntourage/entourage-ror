module Api
  module V1
    module Assistant
      # Offers of help close to a place.
      class HelpOffersController < HelpRequestsController
        private

        def finder_for params
          ::ContributionServices::Finder.new(assistant_user, params)
        end
      end
    end
  end
end
