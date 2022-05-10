module NeighborhoodServices
  class Finder
    class << self
      def search user:, q: nil
        neighborhoods = Neighborhood.not_joined_by(user)

        if q.present?
          neighborhoods = search_by_q(q)
        else
          neighborhoods = default_search(user)
        end

        neighborhoods.inside_perimeter(user.latitude, user.longitude, user.travel_distance)
          .order_by_distance_from(user.latitude, user.longitude)
      end

      def search_by_q q
        Neighborhood.like(q)
      end

      def default_search user
        Neighborhood.order_by_interests_matching(user.interest_list)
          .order_by_activity
      end
    end
  end
end
