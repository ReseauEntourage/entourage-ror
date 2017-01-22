class Partner < ActiveRecord::Base
  validates :name, :large_logo_url, :small_logo_url, presence: true
end
