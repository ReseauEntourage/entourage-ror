module OutingsServices
  class Finder
    attr_reader :user, :latitude, :longitude, :distance, :q, :interests, :before_date

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

      @interests = params[:interests] || []
      @interests += params[:interest_list].split(',') if params[:interest_list].present?
      @interests = @interests.compact.uniq if @interests.present?

      @before_date = params[:within_days].present? ? params[:within_days].to_i.days.from_now.end_of_day : nil
    end

    def base_query
      outings = Outing
        .like(q)
        .active
        .for_user(user)

      if latitude && longitude
        bounding_box_sql = Geocoder::Sql.within_bounding_box(*box, :latitude, :longitude)

        outings = outings.where("(#{bounding_box_sql}) OR online = true")
      end

      # order by starts_at is already in default_scope
      outings.group(:id)
    end

    def find_all
      base_query
        .future_or_past_today
        .ending_before(before_date)
        .match_at_least_one_interest(interests)
    end

    def find_all_participations
      Outing
        .like(q)
        .joins(:join_requests)
        .like(q)
        .where(join_requests: { user: user, status: JoinRequest::ACCEPTED_STATUS })
        .match_at_least_one_interest(interests)
        .group('entourages.id, join_requests.id')
    end

    def find_week_average_between from, to
      weeks = (to.to_time - from.to_time) / 1.week

      outings_count = base_query
        .between(from, to)
        .pluck(:id)
        .count

      outings_count.to_f / weeks
    end

    private

    def box
      Geocoder::Calculations.bounding_box([latitude, longitude], distance, units: :km)
    end
  end
end
