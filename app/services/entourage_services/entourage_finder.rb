module EntourageServices
  class EntourageFinder
    def initialize(user:,
                   status:,
                   type:,
                   latitude:,
                   longitude:,
                   distance:,
                   show_my_entourages_only: false,
                   time_range: 24,
                   page:,
                   per:,
                   before: nil,
                   author: nil)
      @user = user
      @status = status
      @type = type
      @latitude = latitude
      @longitude = longitude
      @distance = distance
      @show_my_entourages_only = show_my_entourages_only
      @time_range = (time_range || 24).to_i
      @page = page
      @per = per
      @before = before
      @author = author
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
                                        }) if show_my_entourages_only
      entourages = entourages.where(user: author) if author
      entourages = entourages.order("entourages.updated_at DESC")
      if page || per
        entourages.page(page).per(per)
      elsif before
        entourages.before(DateTime.parse(before))
      else
        entourages
      end
    end

    private
    attr_reader :user, :status, :type, :latitude, :longitude, :distance, :show_my_entourages_only, :time_range, :page, :per, :before, :author

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