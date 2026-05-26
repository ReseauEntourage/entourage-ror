class WeeklyActivity < ApplicationRecord
  belongs_to :user

  validates_presence_of :user_id, :week_iso
  validates_uniqueness_of :week_iso, scope: :user_id

  scope :recent, -> { order(week_iso: :desc) }
end
