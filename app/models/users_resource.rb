class UsersResource < ApplicationRecord
  include PublishesEvents

  belongs_to :user
  belongs_to :resource

  scope :watched, -> { where(watched: true) }
end
