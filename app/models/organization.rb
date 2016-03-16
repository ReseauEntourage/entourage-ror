class Organization < ActiveRecord::Base
  validates_presence_of [:name, :description, :phone, :address]
  validates_uniqueness_of [:name]
  has_many :users
  has_many :questions

  scope :not_test, -> { where test_organization: false}
  scope :ordered, -> { order("name ASC")}
end
