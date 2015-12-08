class RegistrationRequest < ActiveRecord::Base
  validates :status, :extra, presence: true
end
