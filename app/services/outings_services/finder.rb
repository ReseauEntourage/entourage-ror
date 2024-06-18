module OutingsServices
  class Finder
    attr_reader :user, :latitude, :longitude, :distance, :interests

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

      @interests = params[:interests]
    end

    def find_all
      outings = Outing.active
        .future_or_ongoing
        .match_at_least_one_interest(interests)

      if latitude && longitude
        bounding_box_sql = Geocoder::Sql.within_bounding_box(*box, :latitude, :longitude)

        outings = outings.where("(#{bounding_box_sql}) OR online = true")
      end

      # order by starts_at is already in default_scope
      outings.group(:id)
    end

    private

    def box
      Geocoder::Calculations.bounding_box([latitude, longitude], distance, units: :km)
    end
  end
end
