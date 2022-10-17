class InappNotificationConfiguration < ApplicationRecord
  belongs_to :user

  attribute :configuration, :jsonb_set

  # @caution to be developed based on user configuration
  def is_accepted? instance
    true
  end
end
