class RegistrationRequest < ActiveRecord::Base
  serialize :extra, JSON

  validates :status, :extra, presence: true

  scope :pending, -> { where(status: "pending") }

  def organization_field(field)
    extra["organization"][field]
  end

  def user_field(field)
    extra["user"][field]
  end
end
