class UserNotificationConfiguration < ApplicationRecord
  belongs_to :user

  attribute :configuration, :jsonb_set
end
