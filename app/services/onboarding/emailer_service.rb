module Onboarding
  module EmailerService
    MIN_DELAY = 1.hour

    def self.deliver_incomplete_profile_email
      User.where(id: user_ids).find_each do |user|
        MemberMailer.incomplete_profile(user).deliver_later

        Event.track('onboarding.chat_messages.incomplete_profile.sent', user_id: user.id)
      end
    end

    private

    def self.user_ids
      User.where(community: :entourage, deleted: false)
        .with_event('onboarding.profile.first_name.entered', :name_entered)
        .without_event('onboarding.chat_messages.incomplete_profile.sent')
        .where("name_entered.created_at > '2024-10-01'")
        .where('name_entered.created_at <= ?', MIN_DELAY.ago)
        .where('(goal is null or address_id is null)')
        .pluck(:id)
    end
  end
end
