class AuthenticationProvider < ActiveRecord::Base
  belongs_to :user
  serialize :extra, JSON

  validates :user_id, presence: true, uniqueness: { scope: :provider}
  validates :provider_id, presence: true, uniqueness: true
  validates :provider, :type, presence: true
end
