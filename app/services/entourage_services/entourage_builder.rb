module EntourageServices
  class EntourageBuilder
    def initialize(params:, user:)
      @callback = Callback.new
      @params = params.with_indifferent_access
      @user = user
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
        AsyncService.new(ModerationServices::EntourageModeration).on_create(entourage)
        AsyncService.new(EntourageServices::NeighborhoodAnnouncement).on_create(entourage)

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

      if params.key? :metadata
        params[:metadata].reverse_merge! entourage.metadata
      end

      entourage.assign_attributes(params)

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
        end
      end

      entourage.save
    end

    private
    attr_reader :tour, :user, :callback, :params
  end
end
