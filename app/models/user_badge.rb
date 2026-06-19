class UserBadge < ApplicationRecord
  belongs_to :user

  validates_uniqueness_of :badge_tag, scope: :user_id

  scope :active, -> { where(active: true) }
end
