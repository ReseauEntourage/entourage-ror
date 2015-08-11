class Organization < ActiveRecord::Base
  validates_presence_of [:name, :description, :phone, :address]
  has_many :users
end
