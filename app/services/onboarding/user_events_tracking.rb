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
        Event.track('onboarding.resource.welcome_watched', user_id: self.id)
      end

      def welcome_watched_skipped!
        Event.track('onboarding.resource.welcome_watched_skipped', user_id: self.id)
      end

      def webinar_or_first_steps_joined!
        Event.track('onboarding.outing.webinar_or_first_steps', user_id: self.id)
      end

      def webinar_or_first_steps_joined_skipped!
        Event.track('onboarding.outing.webinar_or_first_steps_skipped', user_id: self.id)
      end

      def papotages_joined!
        Event.track('onboarding.outing.papotages', user_id: self.id)
      end

      # Registration to an event other than the first steps webinar. The legacy event
      # onboarding.outing.papotages is still tracked for papotages: the apps already
      # installed read it to tick the last step.
      def first_event_joined!(outing_type)
        Event.track('onboarding.outing.first_event', user_id: self.id, properties: { outing_type: outing_type })

        papotages_joined! if outing_type == 'papotage'
      end

      def papotages_joined_skipped!
        Event.track('onboarding.outing.papotages_skipped', user_id: self.id)
      end

      def neighborhood_national_joined!
        Event.track('onboarding.neighborhood.national', user_id: self.id)
      end

      def neighborhood_national_joined_skipped!
        Event.track('onboarding.neighborhood.national_skipped', user_id: self.id)
      end

      def onboarding_step_skipped!(step)
        method = SKIPPABLE_STEPS[step]
        return false unless method

        public_send(method)
        true
      end

      private

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
