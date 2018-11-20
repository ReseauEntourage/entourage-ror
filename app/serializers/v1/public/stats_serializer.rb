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
            organizations: organizations_count,
            actions: actions_count,
            events: events_count,
            users: users_count,
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

      def actions_count
        Entourage
          .where(community: :entourage)
          .where(%(group_type = 'action' and coalesce(display_category, 'other') != 'event'))
          .where.not(status: :blacklisted)
          .count
      end

      def events_count
        Entourage
          .where(community: :entourage)
          .where(%(group_type = 'outing' or (group_type = 'action' and coalesce(display_category, 'other') = 'event')))
          .where.not(status: :blacklisted)
          .count
      end

      def users_count
        User
          .where(community: :entourage)
          .where(%(first_sign_in_at is not null or last_sign_in_at is not null))
          .count
      end
    end
  end
end
