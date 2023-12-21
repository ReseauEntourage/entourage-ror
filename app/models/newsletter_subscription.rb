class NewsletterSubscription < ApplicationRecord
  validates :email, :active, presence: true
  validates :email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, on: :create }
  validates :email, uniqueness: true

  scope :activeSuscribers, -> { where(active: true) }
end
