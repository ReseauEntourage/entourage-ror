class Partner < ActiveRecord::Base
  has_many :user_partners, dependent: :destroy
  has_many :users, through: :user_partners

  validates :name, :large_logo_url, :small_logo_url, presence: true
end
