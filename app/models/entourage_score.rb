class EntourageScore < ApplicationRecord
  belongs_to :entourage
  belongs_to :user

  validates :entourage_id, :user_id, :base_score, :final_score, presence: true
end
