class Partner < ActiveRecord::Base
  has_many :users

  validates :name, presence: true

  PLACEHOLDER_URL = "https://s3-eu-west-1.amazonaws.com/entourage-ressources/partner-placeholder.png".freeze

  def large_logo_url
    super.presence || PLACEHOLDER_URL
  end

  CHECKMARK_URL = "https://s3-eu-west-1.amazonaws.com/entourage-ressources/check-small.png"

  def small_logo_url
    super.presence || CHECKMARK_URL
  end
end
