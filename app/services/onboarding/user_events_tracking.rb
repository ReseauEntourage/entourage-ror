module Onboarding
  module UserEventsTracking
    extend ActiveSupport::Concern

    included do
      after_commit :track_onboarding_events
    end

    def self.enable_tracking?
      !Rails.env.test?
    end

    private

    def track_onboarding_events
      return unless Onboarding::UserEventsTracking.enable_tracking?
      return unless previous_changes.key?('first_name') &&
                    previous_changes['first_name'].first.blank? &&
                    previous_changes['first_name'].last.present?

      Event.track('onboarding.profile.first_name.entered', user_id: self.id)
    end
  end
end
