module SolicitationServices
  class Finder
    attr_reader :user, :latitude, :longitude, :distance

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
    end

    def find_all
      solicitations = Solicitation.active.where.not(id: user.solicitation_membership_ids)

      if latitude && longitude
        bounding_box_sql = Geocoder::Sql.within_bounding_box(*box, :latitude, :longitude)

        solicitations = solicitations.where(bounding_box_sql)
      end

      # order by feed_updated_at is already in default_scope
      solicitations.group(:id)
    end

    private

    def box
      Geocoder::Calculations.bounding_box([latitude, longitude], distance, units: :km)
    end
  end
end
