class UserSegmentHistory < ApplicationRecord
  self.table_name = "user_segment_history"

  belongs_to :user

  scope :open, -> { where(valid_to: nil) }
end
