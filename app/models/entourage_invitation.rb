require 'experimental/jsonb_with_schema'

class EntourageInvitation < ApplicationRecord
  MODE_SMS="SMS"

  PENDING_STATUS="pending"
  ACCEPTED_STATUS="accepted"
  REJECTED_STATUS="rejected"
  CANCELLED_STATUS="cancelled"

  STATUS = [ACCEPTED_STATUS, PENDING_STATUS, REJECTED_STATUS, CANCELLED_STATUS]

  belongs_to :invitable, polymorphic: true
  belongs_to :inviter, class_name: "User"
  belongs_to :invitee, class_name: "User", foreign_key: "invitee_id"

  validates :invitable_id, :invitable_type, :status, :inviter, :phone_number, :invitation_mode, presence: true
  validates :invitee, presence: true, if: -> (i) { i.invitation_mode != 'good_waves' }
  validates_inclusion_of :invitation_mode, in: [EntourageInvitation::MODE_SMS, 'good_waves', 'partner_following']
  validates_uniqueness_of :phone_number, scope: [:inviter_id, :invitable_id, :invitable_type]
  validates :metadata, schema: -> (i) { "#{i.invitation_mode}:metadata" }

  scope :status, -> (status) { where(status: status) }

  STATUS.each do |check_status|
    define_method("is_#{check_status}?") do
      status == check_status
    end
  end

  attribute :metadata, Experimental::JsonbWithSchema.new

  def self.json_schema urn
    JsonSchemaService.base do
      case urn
      when 'SMS:metadata'
        {}
      when 'partner_following:metadata'
        {}
      when 'good_waves:metadata'
        {
          name: { type: :string },
          email: { type: [:string, :null] }
        }
      end
    end
  end
end
