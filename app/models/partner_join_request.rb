class PartnerJoinRequest < ApplicationRecord
  belongs_to :user
  belongs_to :partner, required: false

  validates :user_id, presence: true
  validate :validate_id_or_name
  validates :postal_code, presence: true
  validates :partner_role_title, presence: true

  def validate_id_or_name
    if partner_id.blank? && new_partner_name.blank?
      errors.add(:partner_id, "'partner_id' or 'new_partner_name' must be present")
    end
    if !partner_id.nil? && !new_partner_name.nil?
      errors.add(:partner_id, "'new_partner_name' must be nil when 'partner_id' is present")
    end
  end
end
