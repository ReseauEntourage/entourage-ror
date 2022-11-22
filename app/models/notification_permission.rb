class NotificationPermission < ApplicationRecord
  CONFIGURABLE_INSTANCES = %{neighborhood outing chat_message action solicitation contribution}

  belongs_to :user
  validates_presence_of :user

  alias_attribute :notification_permissions, :permissions

  alias_attribute :solicitation, :action
  alias_attribute :contribution, :action

  # @params context ie. chat_message_on_create
  def notify? context, instance, instance_id
    return true unless respond_to?(instance)
    return true unless CONFIGURABLE_INSTANCES.include?(instance.to_s)

    send(instance)
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
