module Onboarding
  module EmailerService
    MIN_DELAY = 1.hour

    def self.deliver_papotages_invitation_j7_email
      User.where(id: papotages_invitation_user_ids_j7).find_each do |user|
        MemberMailer.papotages_invitation_j7(user).deliver_now
      end
    end

    def self.deliver_incomplete_profile_email
      User.where(id: user_ids).find_each do |user|
        MemberMailer.incomplete_profile(user).deliver_later

        Event.track('onboarding.chat_messages.incomplete_profile.sent', user_id: user.id)
      end
    end

    def self.deliver_papotages_invitation_email
      upcoming_papotages = Outing.papotages.future_or_ongoing.limit(3)
      return unless upcoming_papotages.any?

      User.where(id: papotages_invitation_user_ids).find_each do |user|
        MemberMailer.first_steps_papotages_invitation(user, upcoming_papotages).deliver_later
      end
    end

    private

    def self.papotages_invitation_user_ids_j7
      registered_to_papotages = Outing.papotages
        .future_or_ongoing
        .joins(:join_requests)
        .where(join_requests: { status: JoinRequest::ACCEPTED_STATUS })
        .select('join_requests.user_id')

      seven_days_ago = 7.days.ago.to_date

      User.where(community: :entourage, deleted: false)
          .where(first_sign_in_at: seven_days_ago.beginning_of_day..seven_days_ago.end_of_day)
          .where.not(id: registered_to_papotages)
          .pluck(:id)
    end

    def self.user_ids
      User.where(community: :entourage, deleted: false)
        .with_event('onboarding.profile.first_name.entered', :name_entered)
        .without_event('onboarding.chat_messages.incomplete_profile.sent')
        .where("name_entered.created_at > '2024-10-01'")
        .where('name_entered.created_at <= ?', MIN_DELAY.ago)
        .where('(goal is null or address_id is null)')
        .pluck(:id)
    end

    def self.papotages_invitation_user_ids
      user_scope = User.where(community: :entourage, deleted: false).where("email <> ''")

      registered_yesterday = JoinRequest
        .accepted
        .joins(:user, :entourage)
        .merge(user_scope)
        .merge(Outing.first_steps_category)
        .where(join_requests: { created_at: 1.day.ago.all_day })
        .pluck(:user_id)
        .uniq

      already_in_papotage = JoinRequest
        .accepted
        .joins(:entourage)
        .merge(Outing.papotages)
        .where(user_id: registered_yesterday)
        .pluck(:user_id)
        .uniq

      registered_yesterday - already_in_papotage
    end
  end
end
