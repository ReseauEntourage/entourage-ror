class RegistrationRequest < ActiveRecord::Base
  serialize :extra, JSON

  validates :status, :extra, presence: true

  def organization_name
    extra["organization"]["name"]
  end
end
