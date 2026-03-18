module Onboarding
  module UserEventsTracking
    module UserConcern
      extend ActiveSupport::Concern

      included do
        has_many :events

        after_commit :track_onboarding_events
      end

      def welcome_watched!
        Event.track('onboarding.resource.welcome_watched', user_id: self.id)
      end

      def webinar_or_first_steps_joined!
        Event.track('onboarding.outing.webinar_or_first_steps', user_id: self.id)
      end

      def papotages_joined!
        Event.track('onboarding.outing.papotages', user_id: self.id)
      end

      private

      def filled_blank_attribute?(changes, attribute)
        changes.key?(attribute) &&
        changes[attribute].first.blank? &&
        changes[attribute].last.present?
      end

      def track_onboarding_events
        if filled_blank_attribute?(previous_changes, 'first_name')
          Event.track('onboarding.profile.first_name.entered', user_id: self.id)
        end

        # This event isn't used anymore but I left it as it may be interesting
        # for analytics or later use.
        if filled_blank_attribute?(previous_changes, 'goal')
          Event.track('onboarding.profile.goal.entered', user_id: self.id)
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
        Event.track('onboarding.profile.postal_code.entered', user_id: user_id)
      end
    end
  end
end
