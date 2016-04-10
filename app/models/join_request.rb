class JoinRequest < ActiveRecord::Base
  belongs_to :user
  belongs_to :joinable, polymorphic: true

  validates :user_id, :joinable_id, :joinable_type, :status, presence: true
  validates_uniqueness_of :joinable_id, scope: [:user_id]
end
