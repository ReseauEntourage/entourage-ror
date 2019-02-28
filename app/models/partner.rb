class Partner < ActiveRecord::Base
  has_many :users

  validates :name, :description, :large_logo_url, :small_logo_url, presence: true
end
