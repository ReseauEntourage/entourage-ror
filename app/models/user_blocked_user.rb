class UserBlockedUser < ApplicationRecord
  validates_presence_of :user_id
  validates_presence_of :blocked_user_id

  belongs_to :user
  belongs_to :blocked_user, class_name: :User

  scope :with_users, -> (user_ids) {
    return unless user_ids.size >= 2

    where(user_id: user_ids.first, blocked_user_id: user_ids.last).or(
      UserBlockedUser.where(user_id: user_ids.last, blocked_user_id: user_ids.first)
    )
  }
end
