module SolicitationServices
  class Finder
    attr_reader :user, :latitude, :longitude, :distance, :sections, :exclude_memberships

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
      @sections = params[:sections] || []
      @exclude_memberships = params[:exclude_memberships]
    end

    def find_all
      solicitations = Solicitation.active

      if latitude && longitude
        bounding_box_sql = Geocoder::Sql.within_bounding_box(*box, :latitude, :longitude)

        solicitations = solicitations.where(bounding_box_sql)
      end

      if sections.any?
        solicitations = solicitations.where(id: Solicitation.with_sections(sections))
      end

      if exclude_memberships.present?
        solicitations = solicitations.not_joined_by(user)
      end

      # order by created_at is already in default_scope
      solicitations.group(:id)
    end

    private

    def box
      Geocoder::Calculations.bounding_box([latitude, longitude], distance, units: :km)
    end
  end
end
