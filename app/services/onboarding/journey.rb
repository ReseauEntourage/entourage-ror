module Onboarding
  # State of the welcome journey ("parcours de bienvenue") shown on the home of the new members.
  #
  # The journey has 4 steps. A step is crossed when it is done or skipped, see STEPS.
  #
  # The journey is removed from the home as soon as one of these conditions is met:
  #   - completed: the 4 steps are crossed
  #   - hidden: the member hides it
  #   - inactivity: INACTIVITY_DELAY without crossing a step (the counter restarts at each step crossed)
  #   - ceiling: MAX_DURATION after the registration, whatever happens
  #
  # A removed journey never comes back: the removal is persisted as the event
  # onboarding.parcours.removed (properties: reason), which is unique per user.
  #
  # Inactivity and ceiling are computed when read (see #removal_reason) and persisted
  # lazily (see #sync!), by the summary endpoint, before a step is crossed (so that a late
  # step can not reset the counter of a journey which has already expired), and by the
  # onboarding_sequence:remove_expired_journeys task (for the members who do not come back).
  class Journey
    REMOVED_EVENT = 'onboarding.parcours.removed'.freeze
    FIRST_EVENT = 'onboarding.outing.first_event'.freeze

    INACTIVITY_DELAY = 14.days
    MAX_DURATION = 30.days
    # only the members registered recently can still have a journey to remove
    EXPIRY_LOOKBACK = 45.days

    REASONS = %w[completed hidden inactivity ceiling].freeze

    # keys are the values accepted by the onboarding_step_skipped route
    STEPS = {
      'welcome_watched' => {
        done: ['onboarding.resource.welcome_watched'],
        skipped: ['onboarding.resource.welcome_watched_skipped']
      },
      'neighborhood_national' => {
        done: ['onboarding.neighborhood.national'],
        skipped: ['onboarding.neighborhood.national_skipped']
      },
      'webinar_or_first_steps' => {
        done: ['onboarding.outing.webinar_or_first_steps'],
        skipped: ['onboarding.outing.webinar_or_first_steps_skipped']
      },
      # last step: registration to any event but the first steps webinar.
      # onboarding.outing.papotages is the legacy event of this step.
      'papotages' => {
        done: [FIRST_EVENT, 'onboarding.outing.papotages'],
        skipped: ['onboarding.outing.papotages_skipped']
      }
    }.freeze

    attr_reader :user, :now

    # @param now [Time] reference time, injectable for the tests
    def initialize(user, now: Time.zone.now)
      @user = user
      @now = now
    end

    # Removes the journey of the members who did not come back to see it expire.
    def self.remove_expired!(now: Time.zone.now)
      User.where(community: :entourage, deleted: false)
        .where('COALESCE(users.first_sign_in_at, users.created_at) >= ?', now - EXPIRY_LOOKBACK)
        .without_event(REMOVED_EVENT)
        .find_each { |user| new(user, now: now).sync! }
    end

    # @return [Boolean] false when the journey is removed or when the step has been skipped:
    #   the reminders (push, emails) about this step must not be sent
    def reminders_allowed?(step)
      return false if removed?

      !skipped?(step)
    end

    # Removed, or due to be removed (inactivity and ceiling are computed when read).
    def removed?
      persisted? || due_removal.present?
    end

    # @return [String, nil] the persisted reason, or the reason the journey is due to be removed for
    def removal_reason
      persisted? ? persisted_removal_reason : due_removal&.first
    end

    def persisted?
      event_at(REMOVED_EVENT).present?
    end

    def done?(step)
      STEPS.fetch(step)[:done].any? { |name| event_at(name).present? }
    end

    def skipped?(step)
      STEPS.fetch(step)[:skipped].any? { |name| event_at(name).present? }
    end

    def crossed?(step)
      crossed_at(step).present?
    end

    def completed?
      STEPS.each_key.all? { |step| crossed?(step) }
    end

    # Exposed by the summary of the user (home) and by the hide route
    def summary
      { removed: removed?, removed_reason: removal_reason }
    end

    def hide!
      sync!
      remove!('hidden') unless persisted?
    end

    # Persists what is derivable from the events: the registrations to an event done before
    # the "first event" step existed, and the removal when it is due.
    def sync!
      backfill_first_event!

      reason, at = due_removal
      remove!(reason, at) if reason

      removal_reason
    rescue StandardError => e
      Sentry.capture_exception(e)

      nil
    end

    private

    def persisted_removal_reason
      events[REMOVED_EVENT]&.dig(:properties, 'reason')
    end

    # @return [Array(String, Time), nil] the reason and the moment the journey has to be removed
    def due_removal
      return if persisted?

      ceiling_at = started_at + MAX_DURATION
      inactivity_at = (last_crossed_at || started_at) + INACTIVITY_DELAY

      candidates = []
      candidates << ['completed', last_crossed_at] if completed?
      candidates << ['ceiling', ceiling_at] if now >= ceiling_at
      candidates << ['inactivity', inactivity_at] if now >= inactivity_at

      # the earliest condition is the one which removed the journey
      candidates.min_by(&:last)
    end

    def remove!(reason, at = now)
      Event.track(REMOVED_EVENT, user_id: user.id, at: at, properties: { reason: reason })
      reload!
    end

    # Members already registered to an eligible event when the step has been opened to every event.
    # Only for a journey still running: the others are removed without looking at their history.
    def backfill_first_event!
      return if persisted? || crossed?('papotages')
      return if now >= started_at + MAX_DURATION

      join_requests = JoinRequest.accepted
        .where(user_id: user.id)
        .joins(:entourage)
        .where(entourages: { group_type: 'outing' })
        .order(:created_at)
        .to_a
      outings = Outing.where(id: join_requests.map(&:joinable_id)).index_by(&:id)

      join_request, outing_type = join_requests.lazy.filter_map do |request|
        outing = outings[request.joinable_id]
        outing_type = Onboarding::UserEventsTracking.first_event_type(outing) if outing

        [request, outing_type] if outing_type
      end.first

      return unless join_request

      Event.track(FIRST_EVENT, user_id: user.id, at: join_request.created_at, properties: { outing_type: outing_type })
      reload!
    end

    def crossed_at(step)
      config = STEPS.fetch(step)

      (config[:done] + config[:skipped]).filter_map { |name| event_at(name) }.min
    end

    def last_crossed_at
      STEPS.each_key.filter_map { |step| crossed_at(step) }.max
    end

    def started_at
      user.first_sign_in_at || user.created_at
    end

    def event_at(name)
      events[name]&.dig(:created_at)
    end

    def events
      @events ||= Event.where(user_id: user.id)
        .pluck(:name, :created_at, :properties)
        .to_h { |name, created_at, properties| [name, { created_at: created_at, properties: properties }] }
    end

    def reload!
      @events = nil
    end
  end
end
