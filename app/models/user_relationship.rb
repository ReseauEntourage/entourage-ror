class UserRelationship < ActiveRecord::Base
  TYPE_INVITE="TYPE_INVITE"

  belongs_to :source_user, class_name: "User"
  belongs_to :target_user, class_name: "User"

  validates :source_user_id, :target_user_id, :relation_type, presence: true
  validates :relation_type, inclusion: {in: [UserRelationship::TYPE_INVITE]}
end