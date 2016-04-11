module EntourageServices
  class EntourageFinder
    def initialize(user:, status:, type:, latitude:, longitude:, distance:, page:, per:)
      @user = user
      @status = status
      @type = type
      @latitude = latitude
      @longitude = longitude
      @distance = distance
      @page = page
      @per = per
    end

    def entourages
      entourages = Entourage.includes(:join_requests, :user)
      entourages = entourages.where(status: status) if status
      entourages = entourages.where(entourage_type: type) if type
      entourages = entourages.within_bounding_box(box) if latitude && longitude
      entourages = entourages.where("created_at > ?", 1.month.ago)
      entourages.order(created_at: :desc).page(page).per(per)
    end

    private
    attr_reader :user, :status, :type, :latitude, :longitude, :distance, :page, :per

    def box
      Geocoder::Calculations.bounding_box([latitude, longitude],
                                          (distance || 10),
                                          units: :km)
    end
  end
end