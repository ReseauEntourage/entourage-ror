module NeighborhoodServices
  class Finder
    class << self
      def search user:, params: {}
        neighborhoods = if params[:q].present?
          Neighborhood.like(params[:q])
        else
          Neighborhood
        end

        neighborhoods = if params[:latitude].present? && params[:longitude].present?
          neighborhoods.where(id: Neighborhood.inside_perimeter(params[:latitude], params[:longitude], user.travel_distance))
        else
          neighborhoods.where(id: Neighborhood.inside_user_perimeter(user))
        end

        neighborhoods
          .includes([:user, :interests, :future_outings])
          .not_joined_by(user)
          .public_only
          .match_at_least_one_interest(params[:interests])
          .order(Arel.sql(%(zone IS NULL DESC)))
          .order_by_activity
          .order_by_distance_from(user.latitude, user.longitude)
      end

      def search_participations user:, params: {}
        neighborhoods = if params[:q].present?
          Neighborhood.like(params[:q])
        else
          Neighborhood
        end

        neighborhoods
          .joins(:join_requests)
          .where(join_requests: { user: user, status: JoinRequest::ACCEPTED_STATUS })
          .match_at_least_one_interest(params[:interests])
          .order(name: :asc)
      end
    end
  end
end
