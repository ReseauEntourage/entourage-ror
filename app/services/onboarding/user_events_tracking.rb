module Onboarding
  module UserEventsTracking
    SKIPPABLE_STEPS = {
      'welcome_watched' => :welcome_watched_skipped!,
      'webinar_or_first_steps' => :webinar_or_first_steps_joined_skipped!,
      'papotages' => :papotages_joined_skipped!,
      'neighborhood_national' => :neighborhood_national_joined_skipped!
    }.freeze

    # Last step of the welcome journey: registering to any event but the first steps webinar.
    FIRST_EVENT_TYPES = %w[papotage visio physique].freeze

    # @return [String, nil] the type to track for the "first event" step, nil when the outing
    #   is the first steps webinar (it only validates the webinar step)
    def self.first_event_type(outing)
      return if outing.webinar? || outing.first_steps?
      return 'papotage' if outing.papotage?

      outing.online? ? 'visio' : 'physique'
    end

    module UserConcern
      extend ActiveSupport::Concern

      included do
        has_many :events

        after_commit :track_onboarding_events
      end

      def welcome_watched!
        track_onboarding_step('onboarding.resource.welcome_watched')
      end

      def welcome_watched_skipped!
        track_onboarding_step('onboarding.resource.welcome_watched_skipped')
      end

      def webinar_or_first_steps_joined!
        track_onboarding_step('onboarding.outing.webinar_or_first_steps')
      end

      def webinar_or_first_steps_joined_skipped!
        track_onboarding_step('onboarding.outing.webinar_or_first_steps_skipped')
      end

      def papotages_joined!
        track_onboarding_step('onboarding.outing.papotages')
      end

      # Registration to an event other than the first steps webinar. The legacy event
      # onboarding.outing.papotages is still tracked for papotages: the apps already
      # installed read it to tick the last step.
      def first_event_joined!(outing_type)
        track_onboarding_step('onboarding.outing.first_event', properties: { outing_type: outing_type })

        papotages_joined! if outing_type == 'papotage'
      end

      def papotages_joined_skipped!
        track_onboarding_step('onboarding.outing.papotages_skipped')
      end

      def neighborhood_national_joined!
        track_onboarding_step('onboarding.neighborhood.national')
      end

      def neighborhood_national_joined_skipped!
        track_onboarding_step('onboarding.neighborhood.national_skipped')
      end

      # Removes the welcome journey from the home. Idempotent: the first removal reason is kept.
      def hide_onboarding_journey!
        Onboarding::Journey.new(self).hide!
      end

      # Persists the removal of the welcome journey when it is due
      def sync_onboarding_journey!
        Onboarding::Journey.new(self).sync!
      end

      def onboarding_step_skipped!(step)
        method = SKIPPABLE_STEPS[step]
        return false unless method

        public_send(method)
        true
      end

      private

      # Tracks a step of the welcome journey (done or skipped). The removal of the journey is
      # persisted before, so that a step crossed after the delay does not restart the inactivity
      # counter of a journey which has already expired, and after, in case the step completes it.
      def track_onboarding_step(name, properties: nil)
        sync_onboarding_journey!

        Event.track(name, user_id: self.id, properties: properties)

        sync_onboarding_journey!
      end

      def filled_blank_attribute?(changes, attribute)
        changes.key?(attribute) &&
        changes[attribute].first.blank? &&
        changes[attribute].last.present?
      end

      def track_onboarding_events
        if filled_blank_attribute?(previous_changes, 'first_name')
          # @see Onboarding::ChatMessagesService.welcome_message_user_ids
          Event.track('onboarding.profile.first_name.entered', user_id: self.id)
        end
      end
    end

    module AddressConcern
      extend ActiveSupport::Concern

      included do
        after_commit :track_onboarding_events
      end

      private

      def track_onboarding_events
        return unless (['country', 'postal_code'] & previous_changes.keys).any?
        return unless [country, postal_code].all?(&:present?)
        user_id = User.where(address_id: id).pluck(:id).first
        return if user_id.nil?

        # @see Onboarding::ChatMessagesService.welcome_message_user_ids
        Event.track('onboarding.profile.postal_code.entered', user_id: user_id)
      end
    end
  end
end
