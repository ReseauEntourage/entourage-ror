class RegistrationRequest < ActiveRecord::Base
  serialize :extra, JSON

  validates :status, :extra, presence: true
  validates :status, inclusion: { in: %w(pending rejected validated) }

  scope :pending, -> { where(status: "pending") }
  scope :rejected, -> { where(status: "rejected") }
  scope :validated, -> { where(status: "validated") }

  def organization_field(field)
    extra["organization"][field]
  end

  def user_field(field)
    extra["user"][field]
  end
end
