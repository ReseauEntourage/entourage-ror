class AtdSynchronization < ApplicationRecord
  validates :filename, presence: true, uniqueness: true
end
