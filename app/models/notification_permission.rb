class NotificationPermission < ApplicationRecord
  belongs_to :user

  alias_attribute :notification_permissions, :permissions

  # @caution to be developed based on user permissions
  def is_accepted? context, instance, instance_id
    true
  end

  def neighborhood= accepted
    permissions[:neighborhood] = accepted
  end

  def outing= accepted
    permissions[:outing] = accepted
  end

  def private_chat_message= accepted
    permissions[:private_chat_message] = accepted
  end
end
