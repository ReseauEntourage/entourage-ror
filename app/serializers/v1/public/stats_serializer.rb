module V1
  module Public
    class StatsSerializer
      def initialize()
      end

      def as_json
        stats
      end

      private

      def stats
        {
            actions: actions_count,
            events: events_count,
            users: users_count,
        }
      end

      def actions_count
        Entourage
          .where(community: :entourage)
          .where(%(group_type in ('action', 'group') and coalesce(display_category, 'other') != 'event'))
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
