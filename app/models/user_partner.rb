class UserPartner < ActiveRecord::Base
  belongs_to :user
  belongs_to :partner

  validates :user_id, :partner_id, presence: true
  validates_uniqueness_of :partner_id, scope: [:user_id]
end
