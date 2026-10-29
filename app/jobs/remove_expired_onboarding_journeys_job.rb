# Persists the removal of the welcome journey of the members who do not come back to see it expire
# (inactivity, ceiling), see Onboarding::Journey
class RemoveExpiredOnboardingJourneysJob < ApplicationJob
  queue_as :default

  def perform
    Onboarding::Journey.remove_expired!
  end
end
