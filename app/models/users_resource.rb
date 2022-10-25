class UsersResource < ApplicationRecord
  belongs_to :user
  belongs_to :resource

  scope :watched, -> { where(watched: true) }
end
