module EntourageServices
  class EntourageBuilder
    def initialize(params:, user:)
      @callback = Callback.new
      @params = params
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

        callback.on_success.try(:call, entourage.reload)
      else
        callback.on_failure.try(:call, entourage)
      end
      entourage
    end

    def update(entourage:)
      yield callback if block_given?

      if params[:location]
        entourage.longitude = params.dig(:location, :longitude)
        entourage.latitude = params.dig(:location, :latitude)
      end

      if self.class.update(entourage: entourage, params: params.except(:location))
        callback.on_success.try(:call, entourage.reload)
      else
        callback.on_failure.try(:call, entourage)
      end
    end

    def self.update(entourage:, params:)
      moderation_params = params.delete(:outcome)

      entourage.assign_attributes(params)

      entourage.skip_updated_at! if
        entourage.changes.all? do |attribute, change|
          from, to = change

          attribute == 'status' && to == 'closed'
        end

      if entourage.status == 'closed' && moderation_params.present?
        entourage.moderation || entourage.build_moderation
        outcome = {
          true  => 'Oui',
          false => 'Non'
        }[moderation_params[:success]]
        entourage.moderation.action_outcome = outcome unless outcome.nil?
      end

      entourage.save
    end

    private
    attr_reader :tour, :user, :callback, :params
  end
end
