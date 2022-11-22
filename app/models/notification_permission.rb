class NotificationPermission < ApplicationRecord
  belongs_to :user

  alias_attribute :notification_permissions, :permissions

  alias_attribute :solicitation, :action
  alias_attribute :contribution, :action

  # @params context ie. chat_message_on_create
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

  def chat_message
    return true unless permissions && permissions.has_key?("chat_message")
    permissions["chat_message"]
  end

  def action
    return true unless permissions && permissions.has_key?("action")
    permissions["action"]
  end

  # setters
  def neighborhood= accepted
    permissions["neighborhood"] = ActiveModel::Type::Boolean.new.cast(accepted)
  end

  def outing= accepted
    permissions["outing"] = ActiveModel::Type::Boolean.new.cast(accepted)
  end

  def chat_message= accepted
    permissions["chat_message"] = ActiveModel::Type::Boolean.new.cast(accepted)
  end

  def action= accepted
    permissions["action"] = ActiveModel::Type::Boolean.new.cast(accepted)
  end
end
