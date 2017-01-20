module Api
  module V1
    module Public
      class StatsController < Api::V1::Public::BaseController
        def index
          json_stats = $redis.get("entourage::stats")
          if json_stats.blank?
            json_stats = stats
            $redis.setex("entourage::stats", 1.hour, json_stats)
          end
          render json: json_stats
        end

        private
        def stats
          { tours: tours_count,
            encounters: encounters_count,
            organizations: organizations_count}.to_json
        end

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
end
