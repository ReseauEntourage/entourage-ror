class Group < ActiveRecord::Base
	belongs_to :street_person
	has_and_belongs_to_many :users
	has_many :messages
	has_many :encounters
end
