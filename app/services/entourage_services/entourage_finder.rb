module EntourageServices
  class EntourageFinder
    DEFAULT_DISTANCE=10
    FEED_CATEGORY_EXPR = "(case when group_type = 'action' then concat(entourage_type, '_', coalesce(display_category, 'other')) else group_type::text end)"

    def initialize(
      user:,
      types: nil,
      latitude: nil,
      longitude: nil,
      distance: nil,
      page:,
      per:,
      show_past_events: false,
      time_range: 24,
      before: nil,
      partners_only: false,
      # mine
      show_my_entourages_only: false,
      # owns
      author: nil,
      # invitations
      invitee: nil
    )
      @user = user
      @types = formated_types(types)
      @latitude = latitude
      @longitude = longitude
      @distance = [(distance&.to_f || DEFAULT_DISTANCE), 40].min
      @page = page
      @per = per
      @show_past_events = show_past_events=="true"
      @time_range = (time_range || 24).to_i
      @before = before.present? ? (DateTime.parse(before) rescue Time.now) : nil
      @partners_only = partners_only=="true"

      # mine
      @show_my_entourages_only = show_my_entourages_only
      # owns
      @author = author
      # invitations
      @invitee = invitee
    end

    def entourages
      entourages = Entourage.includes(:join_requests, :entourage_invitations, :user)
      entourages = entourages.where(status: :open) # status
      entourages = entourages.where.not(group_type: [:conversation, :group]) # group_type
      entourages = entourages.where("entourages.created_at > ?", time_range.hours.ago)

      if latitude && longitude
        bounding_box_sql = Geocoder::Sql.within_bounding_box(*box, :latitude, :longitude)
        entourages = entourages.where("(#{bounding_box_sql}) OR online = true")
      end

      # outings should be in the future
      unless show_past_events
        entourages = entourages.where("group_type not in (?) or entourages.metadata->>'ends_at' >= ?", [:outing], Time.zone.now)
      end

      # having types
      if types != nil
        entourages = entourages.where("#{FEED_CATEGORY_EXPR} IN (?)", types)
      end

      # as author
      if author
        entourages = entourages.where(user: author)
      end

      # as participant
      if show_my_entourages_only
        entourages = entourages.where(join_requests: {
          user: @user,
          status: JoinRequest::ACCEPTED_STATUS
        })
      end

      # as invitee
      if invitee
        entourages = entourages.where(entourage_invitations: {
          invitee: invitee,
          status: EntourageInvitation::ACCEPTED_STATUS
        })
      end

      # only partners
      if partners_only
        entourages = entourages.joins(:user).where("users.partner_id is not null")
      end

      # pagination
      entourages = order_by_distance(entourages: entourages)

      if page || per
        entourages = entourages.page(page).per(per)
      elsif before
        entourages = entourages.before(DateTime.parse(before)).limit(25)
      end

      entourages = entourages.sort_by(&:created_at).reverse

      entourages
    end

    private
    attr_reader :user, :types, :latitude, :longitude, :distance, :show_my_entourages_only, :time_range, :page, :per, :before, :author, :invitee, :show_past_events, :partners_only

    def box
      Geocoder::Calculations.bounding_box([latitude, longitude], distance, units: :km)
    end

    def formated_types(types)
      FeedServices::Types.formated_for_user(types: types, user: user)
    end

    def order_by_distance(entourages:)
      if latitude && longitude
        distance_from_center = PostgisHelper.distance_from(latitude, longitude)
        entourages.order("case when online then 1 else 2 end", distance_from_center, created_at: :desc)
      else
        entourages
      end
    end
  end
end
