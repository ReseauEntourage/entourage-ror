module EntourageServices
  class EntourageFinder
    def initialize(user:,
                   type:,
                   latitude:,
                   longitude:,
                   distance:,
                   show_my_entourages_only: false,
                   time_range: 24,
                   page:,
                   per:,
                   before: nil,
                   author: nil,
                   invitee: nil)
      @user = user
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
      @invitee = invitee
    end

    def entourages
      entourages = Entourage.visible.includes(:join_requests, :entourage_invitations, :user)
      entourages = entourages.where(status: status) if status
      entourages = entourages.where(entourage_type: formated_types) if type
      entourages = entourages.within_bounding_box(box) if latitude && longitude
      entourages = entourages.where("entourages.created_at > ?", time_range.hours.ago)
      entourages = entourages.where(user: author) if author

      if show_my_entourages_only
        entourages = entourages.where(join_requests: {
          user: @user,
          status: JoinRequest::ACCEPTED_STATUS
        })
      end

      if invitee
        entourages = entourages.where(entourage_invitations: {
          invitee: invitee,
          status: EntourageInvitation::ACCEPTED_STATUS
        })
      end

      entourages = entourages.order("entourages.updated_at DESC")

      if page || per
        entourages.page(page).per(per)
      elsif before
        entourages.before(DateTime.parse(before)).limit(25)
      else
        entourages
      end
    end

    private
    attr_reader :user, :type, :latitude, :longitude, :distance, :show_my_entourages_only, :time_range, :page, :per, :before, :author, :invitee

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
