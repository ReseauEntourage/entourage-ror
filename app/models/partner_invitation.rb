class PartnerInvitation < ActiveRecord::Base
  validates :partner_id, :inviter_id, :invitee_email, :invited_at, :token, presence: true
  validates :invitee_email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }
  validates :token, format: { with: /\A[a-zA-Z0-9]{64}\z/ }

  belongs_to :partner
  belongs_to :inviter, class_name: :User
  belongs_to :invitee, class_name: :User

  include CustomTimestampAttributesForUpdate
  before_save :track_accept

  def generate_new_token
    self.token = self.class.generate_token
  end

  def self.generate_token
    SecureRandom.alphanumeric(64)
  end

  def status
    if accepted_at.present? && invitee_id.present?
      :accepted
    elsif deleted_at.nil? || deleted_at.future?
      :pending
    else
      :deleted
    end
  end

  def accepted?
    status == :accepted
  end

  def pending?
    status == :pending
  end

  private

  def track_accept
    return unless new_record? || invitee_id_changed?

    if invitee_id.present?
      @custom_timestamp_attributes_for_update = [:accepted_at]
    else
      self.accepted_at = nil
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
