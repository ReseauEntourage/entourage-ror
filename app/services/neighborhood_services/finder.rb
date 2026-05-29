module NeighborhoodServices
  class Finder
    attr_reader :user, :latitude, :longitude, :distance, :q, :interests, :national

    def initialize user, params
      @user = user

      if params[:latitude].present? && params[:longitude].present?
        @latitude = params[:latitude]
        @longitude = params[:longitude]
      else
        @latitude = user.latitude
        @longitude = user.longitude
      end

      @distance = params[:travel_distance] || user.travel_distance

      @q = params[:q]
      @national = ActiveRecord::Type::Boolean.new.cast(params[:national])

      @interests = params[:interests] || []
      @interests += params[:interest_list].split(',') if params[:interest_list].present?
      @interests = @interests.compact.uniq if @interests.present?
    end

    def find_all
      neighborhoods = if national
        Neighborhood.where(national: true)
      elsif latitude == user.latitude && longitude == user.longitude
        Neighborhood.where(id: Neighborhood.inside_user_perimeter(user)).or(Neighborhood.where(national: true))
      else
        Neighborhood.where(id: Neighborhood.inside_perimeter(latitude, longitude, distance)).or(Neighborhood.where(national: true))
      end

      neighborhoods
        .like(q)
        .includes([:user, :interests, :future_outings])
        .not_joined_by(user)
        .public_only
        .match_at_least_one_interest(interests)
        .order(national: :desc)
        .order(Arel.sql(%(zone IS NULL DESC)))
        .order_by_activity
        .order_by_distance_from(user.latitude, user.longitude)
    end

    def find_all_participations
      Neighborhood
        .like(q)
        .joins(:join_requests)
        .where(join_requests: { user: user, status: JoinRequest::ACCEPTED_STATUS })
        .match_at_least_one_interest(interests)
        .group('neighborhoods.id, join_requests.id')
        .order_by_unread_messages
    end
  end
end
