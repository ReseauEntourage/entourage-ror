class User < ActiveRecord::Base
  validates :email, presence: true, uniqueness: true
  has_and_belongs_to_many :groups
  has_many :encounters
  has_many :messages
end
