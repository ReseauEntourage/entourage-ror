class UserPhoneChange < ApplicationRecord
  belongs_to :user
  belongs_to :user, foreign_key: :requester_id
end
