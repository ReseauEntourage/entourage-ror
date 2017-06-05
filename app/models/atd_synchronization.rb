class AtdSynchronization < ActiveRecord::Base
  validates :filename, presence: true, uniqueness: true
end
