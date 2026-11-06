module NextSteps
  # What must not be suggested to a user (design.md, decision 6).
  #
  # From the engine's own history (next_steps):
  # - hero: proposed as hero less than 30 days ago, whatever its outcome, or
  #   ignored less than 30 days ago;
  # - others: the active hero, or ignored less than 30 days ago;
  # - both: realised through a tap (lieu solidaire, devenir Animateur).
  #
  # From the domain data, so true even outside the engine ("réalisée : jamais"):
  # events and groups joined, contents read, groups already posted in,
  # entraides answered, ambassadors. Bonnes ondes are the one exception: they
  # are excluded only while the last request is less than 30 days old.
  class Exclusions
    WINDOW = 30.days

    attr_reader :user, :placement, :now

    # @param placement [Symbol] :hero or :others
    def initialize user, placement:, now: Time.zone.now
      @user = user
      @placement = placement
      @now = now
    end

    def since
      now - WINDOW
    end

    # Excluded by the engine's history: the target ids of a kind.
    def excluded_target_ids kind
      engine_keys.select { |key| key[0] == kind }.map { |key| key[2] }.compact
    end

    # Excluded by the engine's history, for a gesture without target.
    def excluded_gesture? kind
      engine_keys.any? { |key| key[0] == kind }
    end

    def joined_outing_ids
      @joined_outing_ids ||= accepted_joinable_ids('Entourage')
    end

    def joined_neighborhood_ids
      @joined_neighborhood_ids ||= accepted_joinable_ids('Neighborhood')
    end

    # Contents read are never proposed again; contents of a path proposed or
    # ignored in the window are excluded like any other target.
    def excluded_resource_ids
      @excluded_resource_ids ||= (
        UsersResource.watched.where(user_id: user.id).pluck(:resource_id) +
        engine_keys.select { |key| key[0] == 'content_path' }.flat_map { |key| key[3] }
      ).uniq
    end

    def posted_neighborhood_ids
      @posted_neighborhood_ids ||= ChatMessage
        .where(user_id: user.id, messageable_type: 'Neighborhood')
        .distinct
        .pluck(:messageable_id)
    end

    def smalltalk_recently_requested?
      return @smalltalk_recently_requested if defined?(@smalltalk_recently_requested)

      @smalltalk_recently_requested = UserSmalltalk.unscoped.where(user_id: user.id).where('created_at > ?', since).exists?
    end

    def ambassador?
      user.ambassador?
    end

    # Users the user cannot write to privately: blocked by them, or blocking them.
    def blocked_user_ids
      @blocked_user_ids ||= (
        UserBlockedUser.where(user_id: user.id).pluck(:blocked_user_id) +
        UserBlockedUser.where(blocked_user_id: user.id).pluck(:user_id)
      ).uniq
    end

    # An entraide is answered when the user joined it, or wrote to its author in
    # a private conversation after it was created (design.md, decision 7).
    def answered_action? action
      return true if accepted_joinable_ids('Entourage').include?(action.id)

      last_at = last_private_message_at_by_user_id(action.user_id)
      last_at.present? && last_at >= action.created_at
    end

    private

    # [kind, target_type, target_id, target_ids] of the next steps that exclude a target
    def engine_keys
      @engine_keys ||= begin
        steps = NextStep.where(user_id: user.id)

        window = if placement == :hero
          steps.where('first_displayed_at > :since OR ignored_at > :since', since: since)
        else
          steps.where(status: 'active').or(steps.where('ignored_at > ?', since))
        end

        realised = steps.where(status: 'realised').where.not(kind: 'smalltalk')

        (window.pluck(:kind, :target_type, :target_id, :target_ids) +
          realised.pluck(:kind, :target_type, :target_id, :target_ids)).uniq
      end
    end

    def accepted_joinable_ids joinable_type
      @accepted_joinable_ids ||= {}
      @accepted_joinable_ids[joinable_type] ||= JoinRequest
        .where(user_id: user.id, joinable_type: joinable_type, status: JoinRequest::ACCEPTED_STATUS)
        .pluck(:joinable_id)
    end

    def last_private_message_at_by_user_id other_user_id
      preload_private_messages([other_user_id])

      @last_private_message_at[other_user_id]
    end

    public

    # Loads, in one query, when the user last wrote privately to each of these
    # users: call it before answered_action? on a batch of entraides.
    def preload_private_messages other_user_ids
      @last_private_message_at ||= {}

      missing = other_user_ids.uniq - @last_private_message_at.keys
      return if missing.empty?

      found = ChatMessage
        .joins("INNER JOIN entourages ON entourages.id = chat_messages.messageable_id AND entourages.group_type = 'conversation'")
        .joins("INNER JOIN join_requests others ON others.joinable_type = 'Entourage' AND others.joinable_id = entourages.id")
        .where(messageable_type: 'Entourage', user_id: user.id)
        .where(others: { user_id: missing })
        .group('others.user_id')
        .maximum('chat_messages.created_at')

      missing.each { |other_user_id| @last_private_message_at[other_user_id] = found[other_user_id] }
    end
  end
end
