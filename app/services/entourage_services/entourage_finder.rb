module EntourageServices
  class EntourageFinder
    include FeedServices::Preloader

    FEED_CATEGORY_EXPR = "(case when group_type = 'action' then concat(entourage_type, '_', coalesce(display_category, 'other')) else group_type::text end)"

    attr_reader :user, :types, :latitude, :longitude, :distance, :page, :per, :show_past_events, :time_range, :before, :partners_only, :no_outings, :show_my_entourages_only, :author, :invitee, :status, :search

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
      no_outings: false,
      # joined
      show_my_entourages_only: false,
      # owned
      author: nil,
      # invitations
      invitee: nil,
      status: nil,
      search: nil
    )
      @user = user
      @types = formated_types(types)
      @latitude = latitude
      @longitude = longitude
      @distance = UserService.travel_distance(user: user, forced_distance: distance)
      @page = page
      @per = per
      @show_past_events = show_past_events=="true"
      @time_range = (time_range || 24).to_i
      @before = before.present? ? (DateTime.parse(before) rescue Time.now) : nil
      @partners_only = partners_only=="true"
      @no_outings = no_outings

      # joined
      @show_my_entourages_only = show_my_entourages_only
      # owned
      @author = author
      # invitations
      @invitee = invitee
      @status = status
      @search = search
    end

    def entourages
      entourages = Entourage.includes(:join_requests, :entourage_invitations, :user)
      entourages = entourages.where(status: status || :open) # status
      entourages = entourages.where.not(group_type: [:conversation, :group]) # group_type
      entourages = entourages.where.not(group_type: [:outing]) if no_outings
      entourages = entourages.where("entourages.created_at > ?", time_range.hours.ago)
      entourages = entourages.like(search) if @search.present?

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

      # entourages = entourages.preload(user: :partner)
      entourages = entourages.sort_by(&:created_at).reverse
      # Note: entourages is now an Array.

      preload_user_join_requests(entourages)
      preload_chat_messages_counts(entourages)

      if page == 1
        pinned = EntourageServices::Pins.find(user, types)

        pinned.compact.uniq.reverse.each do |action|
          entourages = pin(action, entourages: entourages)
        end
      end

      entourages
    end

    private

    def box
      Geocoder::Calculations.bounding_box([latitude, longitude], distance, units: :km)
    end

    def formated_types(types)
      FeedServices::Types.formated_for_user(types: types, user: user)
    end

    def order_by_distance(entourages:)
      if latitude && longitude
        distance_from_center = PostgisHelper.distance_from(latitude, longitude)

        entourages
          .order(Arel.sql("case when online then 1 else 2 end"))
          .order(Arel.sql(distance_from_center))
          .order(created_at: :desc)
      else
        entourages
      end
    end

    def preload_user_join_requests(entourages)
      entourage_ids = entourages.map(&:id)

      return if entourage_ids.empty?

      user_join_requests = user.join_requests.where(joinable_type: 'Entourage').where(joinable_id: entourage_ids)
      user_join_requests = user_join_requests.map do |join_request|
        [join_request.joinable_id, join_request]
      end.to_h

      entourages.each do |entourage|
        entourage.current_join_request = user_join_requests[entourage.id]
      end
    end

    def pin entourage_id, entourages:
      entourages = entourages.to_a

      index = entourages.index { |e| e.id == entourage_id }

      if index
        entourage = entourages.delete_at(index)
      else
        entourage = Entourage.visible.find_by(id: entourage_id)
        return entourages unless entourage
        entourage.current_join_request = nil
        entourage.number_of_unread_messages = 0
      end

      entourages.insert(0, entourage)
      entourages
    end
  end
end
