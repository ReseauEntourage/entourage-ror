module EntourageServices
  class EntourageFinder
    FEED_CATEGORY_EXPR = "(case when group_type = 'action' then concat(entourage_type, '_', coalesce(display_category, 'other')) else group_type::text end)"

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
      @types = formated_types(types)
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

      if latitude && longitude
        bounding_box_sql = Geocoder::Sql.within_bounding_box(*box, :latitude, :longitude)
        entourages = entourages.where("(#{bounding_box_sql}) OR online = true")
      end

      # outings should be in the future
      unless show_past_events
        entourages = entourages.where("group_type not in (?) or metadata->>'ends_at' >= ?", [:outing], Time.zone.now)
      end

      # having types
      if types != nil
        entourages = entourages.where("#{FEED_CATEGORY_EXPR} IN (?)", types)
      end

      # as author
      if author
        entourages = entourages.where(user: author)
      end

      # as owner
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
    attr_reader :user, :types, :latitude, :longitude, :distance, :show_my_entourages_only, :time_range, :page, :per, :before, :author, :invitee, :show_past_events, :partners_only

    def box
      Geocoder::Calculations.bounding_box([latitude, longitude],
                                          (distance || 10),
                                          units: :km)
    end

    def formated_types(types)
      FeedServices::Types.formated_for_user(types: types, user: user)
    end
  end
end
