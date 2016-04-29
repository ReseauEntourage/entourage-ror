class EntourageInvitation < ActiveRecord::Base
  MODE_SMS="SMS"

  belongs_to :invitable, polymorphic: true
  belongs_to :inviter, class_name: "User"
  belongs_to :invitee, class_name: "User", foreign_key: "invitee_id"

  validates :invitable, :inviter, :invitee, :phone_number, :invitation_mode, presence: true
  validates_inclusion_of :invitation_mode, in: [EntourageInvitation::MODE_SMS]
  validates_uniqueness_of :phone_number, scope: [:inviter_id, :invitable_id, :invitable_type]
end
