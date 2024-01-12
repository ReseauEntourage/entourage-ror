class UserReaction < ApplicationRecord
  belongs_to :user
  belongs_to :reaction
  belongs_to :instance, polymorphic: true

  validates_uniqueness_of :user_id, scope: [:instance_id, :instance_type], message: "You can only react once"
end
