class Organization < ActiveRecord::Base
  validates_presence_of [:name, :description, :phone, :address]
  validates_uniqueness_of [:name]
  has_many :users
end
