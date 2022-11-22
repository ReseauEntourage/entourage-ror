class NotificationPermission < ApplicationRecord
  belongs_to :user

  alias_attribute :notification_permissions, :permissions

  # @caution to be developed based on user permissions
  def is_accepted? context, instance, instance_id
    true
  end

  # accessors
  def neighborhood
    return true unless permissions && permissions.has_key?("neighborhood")
    permissions["neighborhood"]
  end

  def outing
    return true unless permissions && permissions.has_key?("outing")
    permissions["outing"]
  end

  def private_chat_message
    return true unless permissions && permissions.has_key?("private_chat_message")
    permissions["private_chat_message"]
  end

  # setters
  def neighborhood= accepted
    permissions[:neighborhood] = ActiveModel::Type::Boolean.new.cast(accepted)
  end

  def outing= accepted
    permissions[:outing] = ActiveModel::Type::Boolean.new.cast(accepted)
  end

  def private_chat_message= accepted
    permissions[:private_chat_message] = ActiveModel::Type::Boolean.new.cast(accepted)
  end
end
