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
          .includes([:user, :interests, :future_outings])
          .not_joined_by(user)
          .public_only
          .where(id: Neighborhood.inside_user_perimeter(user))
          .order(national: :desc)
          .order(Arel.sql(%(zone IS NULL DESC)))
          .order_by_activity
          .order_by_distance_from(user.latitude, user.longitude)
      end
    end
  end
end
