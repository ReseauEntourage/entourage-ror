class PartnerInvitation < ApplicationRecord
  validates :partner_id, :inviter_id, :invitee_email, :invited_at, :token, presence: true
  validates :invitee_email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }
  validates :token, format: { with: /\A[a-zA-Z0-9]{64}\z/ }
  validates :status, presence: true,
                     inclusion: { in: %w(pending deleted accepted outdated) }

  validates :invitee_id, :accepted_at, absence: true, if: Proc.new { |i| i.pending?  || i.deleted?  }
  validates :invitee_id, presence: true, if: Proc.new { |i| i.accepted? || i.outdated? }

  validates :deleted_at, absence:  true, unless: :deleted?

  belongs_to :partner
  belongs_to :inviter, class_name: :User
  belongs_to :invitee, class_name: :User, optional: true # some records have null invitee_id

  include CustomTimestampAttributesForUpdate
  before_save :track_accept
  before_save :track_delete

  def generate_new_token
    self.token = self.class.generate_token
  end

  def self.generate_token
    SecureRandom.alphanumeric(64)
  end

  def accepted?; status == 'accepted'; end
  def pending?;  status == 'pending';  end
  def deleted?;  status == 'deleted';  end
  def outdated?; status == 'outdated'; end

  private

  def track_accept
    return unless new_record? || invitee_id_changed?

    if invitee_id.present?
      @custom_timestamp_attributes_for_update = ["accepted_at"]
    else
      self.accepted_at = nil
    end
  end

  def track_delete
    return unless new_record? || status_changed?

    if deleted?
      @custom_timestamp_attributes_for_update = ["deleted_at"]
    else
      self.deleted_at = nil
    end
  end

  # If the record creation fails because of an non-unique token,
  # generates a new token and retries (at most 3 times in total)
  def _create_record
    tries ||= 1
    transaction(requires_new: true) { super }
  rescue ActiveRecord::RecordNotUnique => e
    raise e unless /Key \(token\)=.* already exists/ === e.cause.error
    logger.info "type=partner_invitation.token.not_unique tries=#{tries}"
    raise e if tries == 3
    generate_new_token
    tries += 1
    retry
  end
end
