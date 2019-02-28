class Partner < ActiveRecord::Base
  # TODO(partner)
  # has_many :users

  validates :name, :description, :large_logo_url, :small_logo_url, presence: true
end
