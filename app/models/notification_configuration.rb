class NotificationConfiguration < ApplicationRecord
  belongs_to :user

  attribute :configuration, :jsonb_set

  # @caution to be developed based on user configuration
  def is_accepted? context, instance, instance_id
    true
  end
end
