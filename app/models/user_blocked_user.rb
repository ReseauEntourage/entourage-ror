class UserBlockedUser < ApplicationRecord
  validates_presence_of :user_id
  validates_presence_of :blocked_user_id
  validates_inclusion_of :status, in: ["blocked", "not_blocked"], allow_nil: false, default: :blocked

  belongs_to :user
  belongs_to :blocked_user, class_name: :User
end
