module EntourageServices
  class EntourageBuilder
    def initialize(params:, user:)
      @callback = Callback.new
      @params = params.with_indifferent_access
      @user = user

      @recipient_consent_obtained =
        case @params.delete(:recipient_consent_obtained)
        when *ActiveRecord::ConnectionAdapters::Column::TRUE_VALUES
          true
        when *ActiveRecord::ConnectionAdapters::Column::FALSE_VALUES
          false
        when nil
          nil
        else
          :invalid
        end
    end

    def create
      yield callback if block_given?

      entourage = Entourage.new(params.except(:location))
      entourage.group_type ||= 'action'
      entourage.entourage_type = 'contribution' if entourage.group_type != 'action'
      entourage.longitude = params.dig(:location, :longitude)
      entourage.latitude = params.dig(:location, :latitude)
      entourage.user = user
      entourage.uuid = SecureRandom.uuid

      allowed_group_types =
        case user.community
        when 'entourage' then ['action', 'outing']
        when 'pfp'       then ['outing']
        end
      entourage.group_type = nil unless entourage.group_type.in? allowed_group_types

      if recipient_consent_obtained == :invalid
        entourage.errors.add(:base, "recipient_consent_obtained must be a boolean")
        callback.on_failure.try(:call, entourage)
        return false
      end

      entourage.status =
        if entourage.group_type     == 'action' &&
           entourage.entourage_type == 'ask_for_help' &&
           recipient_consent_obtained == false
          :suspended
        else
          :open
        end

      text = "#{entourage.title} #{entourage.description}"
      entourage.category = EntourageServices::CategoryLexicon.new(text: text).category

      if entourage.save
        #When you start an entourage you are automatically added to members of the tour
        join_request = JoinRequest.create(joinable: entourage, user: user)

        joinable = entourage
        join_request.role =
          case [joinable.community, joinable.group_type]
          when ['entourage', 'tour']   then 'creator'
          when ['entourage', 'action'] then 'creator'
          when ['entourage', 'outing'] then 'organizer'
          when ['pfp',       'outing'] then 'organizer'
          else raise 'Unhandled'
          end

        TourServices::JoinRequestStatus.new(join_request: join_request).accept!
        # AsyncService.new(ModerationServices::EntourageModeration).on_create(entourage)
        AsyncService.new(EntourageServices::NeighborhoodAnnouncement).on_create(entourage)
        AsyncService.new(FollowingService).on_create_entourage(entourage)
        CommunityLogic.for(entourage).group_created(entourage)

        if recipient_consent_obtained != nil
          entourage.moderation || entourage.build_moderation
          entourage.moderation.action_recipient_consent_obtained = {
            true  => 'Oui',
            false => 'Non',
          }[recipient_consent_obtained]
          entourage.moderation.save
        end

        callback.on_success.try(:call, entourage.reload)
      else
        callback.on_failure.try(:call, entourage)
      end
      entourage
    end

    def update(entourage:)
      yield callback if block_given?

      params.delete(:group_type)

      if params[:location]
        entourage.longitude = params.dig(:location, :longitude)
        entourage.latitude = params.dig(:location, :latitude)
      end

      if self.class.update(entourage: entourage, params: params.except(:location))
        entourage.reload
        AsyncService.new(EntourageServices::NeighborhoodAnnouncement).on_update(entourage)
        callback.on_success.try(:call, entourage)
      else
        callback.on_failure.try(:call, entourage)
      end
    end

    def self.update(entourage:, params:)
      moderation_params = params.delete(:outcome)

      sent_metadata = params[:metadata]
      if params.key? :metadata
        params[:metadata] = params[:metadata].reverse_merge entourage.metadata
      end

      # prevent category change for groups (good_waves)
      if entourage.group_type == 'group'
        params.delete(:entourage_type)
        params.delete(:display_category)
        params.delete(:public)
      end

      entourage.assign_attributes(params)

      # reset ends_at if only starts_at was set
      if entourage.group_type == 'outing' &&
         sent_metadata&.key?(:starts_at) &&
         !sent_metadata&.key?(:ends_at)

        entourage.metadata[:ends_at] = nil
      end

      entourage.skip_updated_at! if
        entourage.changes.all? do |attribute, change|
          from, to = change

          attribute == 'status' && to == 'closed'
        end

      if entourage.status == 'closed' && moderation_params.present?
        entourage.moderation || entourage.build_moderation

        entourage.moderation.action_outcome =
          case moderation_params[:success]
          when *ActiveRecord::ConnectionAdapters::Column::TRUE_VALUES
            'Oui'
          when *ActiveRecord::ConnectionAdapters::Column::FALSE_VALUES
            'Non'
          else
            entourage.errors.add(:base, "outcome.success must be a boolean")
            return false
          end

        if entourage.moderation.action_outcome_changed?
          entourage.moderation.action_outcome_reported_at = Time.now
          entourage.moderation.moderation_comment = (
            (entourage.moderation.moderation_comment || '').lines.map(&:chomp) +
            ["Aboutissement passé à \"#{entourage.moderation.action_outcome}\" " +
             "par le créateur de l'action " +
             "le #{I18n.l Time.now, format: '%-d %B %Y à %H:%M'}."]
          ).join("\n")

          if entourage.group_type == 'action' &&
             entourage.moderation.action_outcome == 'Oui'
            join_request = JoinRequest.where(joinable: entourage, user: entourage.user).first
            CommunityLogic.for(entourage).action_success_creator(join_request)
          end
        end
      end

      publish_status_update =
        entourage.status_changed? &&
        entourage.status.in?(['closed', 'open'])

      outcome =
        if entourage.status == 'closed' &&
           entourage.moderation&.action_outcome_changed?
          {
            'Oui' => true,
            'Non' => false,
          }[entourage.moderation.action_outcome]
        else
          nil
        end

      success = entourage.save

      if success && publish_status_update
        ChatMessage.create(
          messageable: entourage,
          user_id: entourage.user_id,
          message_type: :status_update,
          metadata: {
            status: entourage.status,
            outcome_success: outcome
          }
        )
      end

      success
    end

    private
    attr_reader :tour, :user, :callback, :params, :recipient_consent_obtained
  end
end
