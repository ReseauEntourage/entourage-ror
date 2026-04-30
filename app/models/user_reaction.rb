class UserReaction < ApplicationRecord
  belongs_to :user
  belongs_to :reaction
  belongs_to :instance, polymorphic: true

  validates_uniqueness_of :user_id, scope: [:instance_id, :instance_type], message: 'You can only react once'

  after_create :check_badges

  def check_badges
    BadgesService.check_bienvenue(user)
  end
end
