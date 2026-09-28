class EntourageInvitation < ApplicationRecord
  MODE_SMS='SMS'

  PENDING_STATUS='pending'
  ACCEPTED_STATUS='accepted'
  REJECTED_STATUS='rejected'
  CANCELLED_STATUS='cancelled'

  STATUS = [ACCEPTED_STATUS, PENDING_STATUS, REJECTED_STATUS, CANCELLED_STATUS]

  belongs_to :invitable, class_name: 'Entourage'
  belongs_to :inviter, class_name: 'User'
  belongs_to :invitee, class_name: 'User', foreign_key: 'invitee_id'

  validates :invitable_id, :status, :inviter, :phone_number, :invitation_mode, presence: true
  validates_inclusion_of :invitation_mode, in: [EntourageInvitation::MODE_SMS, 'partner_following']
  validates_uniqueness_of :phone_number, scope: [:inviter_id, :invitable_id]
  validates :metadata, schema: -> (i) { "#{i.invitation_mode}:metadata" }

  scope :status, -> (status) { where(status: status) }

  STATUS.each do |check_status|
    define_method("is_#{check_status}?") do
      status == check_status
    end
  end

  attribute :metadata, :jsonb_with_schema

  attr_writer :join_request # @see Preloaders::EntourageInvitation.preload_join_requests

  # join request of the invitee to the invitable
  def join_request
    return @join_request if defined?(@join_request)

    @join_request = JoinRequest.where(joinable: invitable, user_id: invitee_id).first
  end

  def self.json_schema urn
    JsonSchemaService.base do
      case urn
      when 'SMS:metadata'
        {}
      when 'partner_following:metadata'
        {}
      end
    end
  end

  def invitable_type
    'Entourage'
  end
end
