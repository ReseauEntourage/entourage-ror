class EntourageInvitation < ActiveRecord::Base
  MODE_SMS="SMS"

  PENDING_STATUS="pending"
  ACCEPTED_STATUS="accepted"
  REJECTED_STATUS="rejected"
  CANCELLED_STATUS="cancelled"

  belongs_to :invitable, polymorphic: true
  belongs_to :inviter, class_name: "User"
  belongs_to :invitee, class_name: "User", foreign_key: "invitee_id"

  validates :invitable_id, :invitable_type, :status, :inviter, :invitee, :phone_number, :invitation_mode, presence: true
  validates_inclusion_of :invitation_mode, in: [EntourageInvitation::MODE_SMS]
  validates_uniqueness_of :phone_number, scope: [:inviter_id, :invitable_id, :invitable_type]

  scope :status, -> (status) { where(status: status) }
end
