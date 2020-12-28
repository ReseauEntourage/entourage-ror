class Following < ApplicationRecord
  belongs_to :user
  belongs_to :partner

  validates :user_id, presence: true
  validates :partner_id, presence: true
  validates :active, inclusion: [true, false], allow_nil: false
end
