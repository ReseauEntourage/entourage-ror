class SendFirstStepsInvitationJob < ApplicationJob
  def perform(user_id)
    user = User.find_by(id: user_id)

    return unless user.present?
    return if already_registered_to_first_steps?(user_id)

    MemberMailer.first_steps_invitation(user).deliver_now
  end

  private

  def already_registered_to_first_steps?(user_id)
    Outing.first_steps_category
      .joins(:join_requests)
      .where(join_requests: { user_id: user_id, status: 'accepted' })
      .exists?
  end
end
