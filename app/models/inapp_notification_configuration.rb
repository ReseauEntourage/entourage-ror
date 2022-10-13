class InappNotificationConfiguration < ApplicationRecord
  belongs_to :user

  attribute :configuration, :jsonb_set

  # @caution to be developed based on user configuration
  def is_accepted? action:, instance:
    true
  end

  def not_accepted? action:, instance:
    !is_accepted(action: action, instance: instance)
  end
end
