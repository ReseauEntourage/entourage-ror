module NeighborhoodServices
  class Finder
    attr_reader :user, :latitude, :longitude, :distance, :q, :interests, :params

    def initialize user, params
      @user = user
      @params = params

      if params[:latitude].present? && params[:longitude].present?
        @latitude = params[:latitude]
        @longitude = params[:longitude]
      else
        @latitude = user.latitude
        @longitude = user.longitude
      end

      @distance = params[:travel_distance] || user.travel_distance

      @q = params[:q]

      @interests = params[:interests] || []
      @interests += params[:interest_list].split(',') if params[:interest_list].present?
      @interests = @interests.compact.uniq if @interests.present?
    end

    def find_all
      neighborhoods = if latitude == user.latitude && longitude == user.longitude
        Neighborhood.where(id: Neighborhood.inside_user_perimeter(user))
      else
        Neighborhood.where(id: Neighborhood.inside_perimeter(latitude, longitude, distance))
      end

      neighborhoods
        .like(q)
        .includes([:user, :interests, :future_outings])
        .not_joined_by(user)
        .public_only
        .match_at_least_one_interest(interests)
        .order(Arel.sql(%(zone IS NULL DESC)))
        .order_by_activity
        .order_by_distance_from(user.latitude, user.longitude)
    end

    def find_all_participations
      neighborhoods = Neighborhood
        .joins(:join_requests)
        .like(q)
        .where(join_requests: { user: user, status: JoinRequest::ACCEPTED_STATUS })
        .match_at_least_one_interest(interests)
        .order(name: :asc)

      # filter by localisation only whenever user filters by distance in the query
      if latitude && longitude && param_distance?
        neighborhoods = neighborhoods.where(id: Neighborhood.inside_perimeter(latitude, longitude, distance))
      end

      neighborhoods
    end

    private

    def param_distance?
      params[:travel_distance].present?
    end
  end
end
