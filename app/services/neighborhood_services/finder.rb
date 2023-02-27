module NeighborhoodServices
  class Finder
    class << self
      def search user:, q: nil
        neighborhoods = if q.present?
          search_by_q(q)
        else
          default_search(user)
        end

        neighborhoods
          .includes([:user, :members, :interests, :ongoing_outings, :past_outings, :future_outings])
          .not_joined_by(user)
          .public_only
          .where(id: Neighborhood.inside_user_perimeter(user))
          .order_by_distance_from(user.latitude, user.longitude)
      end

      def search_by_q q
        Neighborhood.like(q)
      end

      def default_search user
        Neighborhood.order_by_activity
      end
    end
  end
end
