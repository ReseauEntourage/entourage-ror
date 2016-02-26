module Api
  module V0
    class StatsController < Api::V0::BaseController
      skip_before_filter :authenticate_user!

      def index
        render json: { tours: tours_count,
                       encounters: encounters_count,
                       organizations: organizations_count}.to_json
      end

      private
      def tours_count
        Tour.joins(user: :organization).where("organizations.test_organization=false").group("tours.id").count.count
      end

      def encounters_count
        Encounter.joins(tour: {user: :organization}).where("organizations.test_organization=false").group("encounters.id").count.count
      end

      def organizations_count
        Organization.not_test.count
      end
    end
  end
end

