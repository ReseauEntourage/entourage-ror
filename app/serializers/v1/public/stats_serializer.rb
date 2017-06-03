module V1
  module Public
    class StatsSerializer
      def initialize()
      end

      def to_json
        stats
      end

      private

      def stats
        {
            tours: tours_count,
            encounters: encounters_count,
            organizations: organizations_count
        }
      end

      def tours_count
        Tour.joins(user: :organization).where('organizations.test_organization=false').group('tours.id').count.count
      end

      def encounters_count
        Encounter.joins(tour: {user: :organization}).where('organizations.test_organization=false').group('encounters.id').count.count
      end

      def organizations_count
        Organization.not_test.count
      end
    end
  end
end
