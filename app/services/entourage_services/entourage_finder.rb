module EntourageServices
  class EntourageFinder
    def initialize(user:, status:, type:, latitude:, longitude:, distance:, show_only_my_entourages: false, time_range: 24, page:, per:)
      @user = user
      @status = status
      @type = type
      @latitude = latitude
      @longitude = longitude
      @distance = distance
      @show_only_my_entourages = show_only_my_entourages
      @time_range = time_range.to_i
      @page = page
      @per = per
    end

    def entourages
      entourages = Entourage.includes(:join_requests, :user)
      entourages = entourages.where(status: status) if status
      entourages = entourages.where(entourage_type: formated_types) if type
      entourages = entourages.within_bounding_box(box) if latitude && longitude
      entourages = entourages.where("entourages.created_at > ?", time_range.hours.ago)
      entourages = entourages.where(join_requests:
                                        {
                                            user: @user,
                                            status: JoinRequest::ACCEPTED_STATUS
                                        }) if show_only_my_entourages
      entourages.order(created_at: :desc).page(page).per(per)
    end

    private
    attr_reader :user, :status, :type, :latitude, :longitude, :distance, :show_only_my_entourages, :time_range, :page, :per

    def box
      Geocoder::Calculations.bounding_box([latitude, longitude],
                                          (distance || 10),
                                          units: :km)
    end

    def formated_types
      type.gsub(" ", "").split(",")
    end
  end
end