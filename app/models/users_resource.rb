class UsersResource < ApplicationRecord
  belongs_to :user
  belongs_to :resource

  scope :displayed, -> { where(displayed: true) }
end
