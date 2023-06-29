module NeighborhoodServices
  class Finder
    class << self
      def search user:, q: nil
        neighborhoods = if q.present?
          Neighborhood.like(q)
        else
          Neighborhood
        end

        neighborhoods
          .includes([:user, :members, :interests, :ongoing_outings, :past_outings, :future_outings])
          .not_joined_by(user)
          .public_only
          .where(id: Neighborhood.inside_user_perimeter(user))
          .order_by_interests_matching(user.interest_list)
          .order_by_activity
          .order_by_distance_from(user.latitude, user.longitude)
      end
    end
  end
end
