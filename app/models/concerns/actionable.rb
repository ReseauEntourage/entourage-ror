module Actionable
  extend ActiveSupport::Concern

  included do
    after_validation :add_creator_as_member, if: :new_record?
    after_create :after_create_send_mail_to_creator
  end

  def add_creator_as_member
    return unless user.present?
    return if join_requests.map(&:user_id).include?(user.id)

    join_requests << JoinRequest.new(user: user, joinable: self, status: :accepted, role: :creator)
  end

  def after_create_send_mail_to_creator
    AsyncService.new(FollowingService).on_create_entourage(id)
  end
end
