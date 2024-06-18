module NeighborhoodServices
  class Finder
    class << self
      def search user:, params: {}
        neighborhoods = if params[:q].present?
          Neighborhood.like(params[:q])
        else
          Neighborhood
        end

        neighborhoods
          .includes([:user, :interests, :future_outings])
          .not_joined_by(user)
          .public_only
          .where(id: Neighborhood.inside_user_perimeter(user))
          .match_at_least_one_interest(params[:interests])
          .order(Arel.sql(%(zone IS NULL DESC)))
          .order_by_activity
          .order_by_distance_from(user.latitude, user.longitude)
      end
    end
  end
end
