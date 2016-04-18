class EntourageInvitation < ActiveRecord::Base
  belongs_to :invitable, polymorphic: true
  belongs_to :inviter, class_name: "User"
  belongs_to :invitee, class_name: "User", foreign_key: "invitee_id"
end
