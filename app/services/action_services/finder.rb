module ActionServices
  class Finder
    attr_reader :user, :latitude, :longitude, :distance, :sections

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
    end

    def find_all
      actions = Action.active.where.not(id: user.action_membership_ids)

      if latitude && longitude
        bounding_box_sql = Geocoder::Sql.within_bounding_box(*box, :latitude, :longitude)

        actions = actions.where(bounding_box_sql)
      end

      if sections.any?
        actions = actions.where(id: Action.with_sections(sections))
      end

      # order by created_at is already in default_scope
      actions.group(:id)
    end

    private

    def box
      Geocoder::Calculations.bounding_box([latitude, longitude], distance, units: :km)
    end
  end
end
