class ModeratorRead < ActiveRecord::Base
  belongs_to :moderatable, polymorphic: true
  belongs_to :user

  validates_uniqueness_of :user_id, scope: [:moderatable_id, :moderatable_type]
end
