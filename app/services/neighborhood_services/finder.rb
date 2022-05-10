module NeighborhoodServices
  class Finder
    class << self
      def search user:, q: nil
        neighborhoods = if q.present?
          search_by_q(q)
        else
          default_search
        end

        Neighborhood.not_joined_by(user)
          .inside_perimeter(user.latitude, user.longitude, user.travel_distance)
          .order_by_distance_from(user.latitude, user.longitude)
      end

      def search_by_q q
        Neighborhood.like(q)
      end

      def default_search
        Neighborhood.order_by_interests_matching(user.interest_list)
          .order_by_activity
      end
    end
  end
end
