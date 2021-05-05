class AtdUser < ApplicationRecord
  belongs_to :user

  validates :atd_id, presence: true

  validates_uniqueness_of :atd_id
end
