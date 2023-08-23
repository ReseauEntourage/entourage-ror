class NotificationPermission < ApplicationRecord
  INAPP_INSTANCES = %{neighborhood outing contribution solicitation user}
  PUSH_INSTANCES = %{neighborhood outing contribution solicitation conversation user}

  belongs_to :user
  validates_presence_of :user

  alias_attribute :notification_permissions, :permissions

  alias_attribute :solicitation, :action
  alias_attribute :contribution, :action

  class << self
    def notify_inapp? user, instance, instance_id
      return true unless instance
      return true unless instance_id
      return false unless INAPP_INSTANCES.include?(instance.to_s)

      notify?(user, instance, instance_id)
    end

    def notify_push? user, instance, instance_id
      return true unless instance
      return true unless instance_id
      return false unless PUSH_INSTANCES.include?(instance.to_s)

      notify?(user, instance, instance_id)
    end

    def notify? user, instance, instance_id
      return true unless permission = user.notification_permission

      permission.notify?(instance, instance_id)
    end
  end

  def notify? instance, instance_id
    return false unless respond_to?(instance)

    send(instance, instance_id)
  end

  # accessors
  def neighborhood instance_id = nil
    return true unless permissions && permissions.has_key?("neighborhood")
    permissions["neighborhood"]
  end

  def outing instance_id = nil
    return true unless permissions && permissions.has_key?("outing")
    permissions["outing"]
  end

  def conversation instance_id = nil
    return chat_message(instance_id) if Entourage.find(instance_id).conversation?

    action(instance_id)
  end

  def chat_message instance_id = nil
    return true unless permissions && permissions.has_key?("chat_message")
    permissions["chat_message"]
  end

  def action instance_id = nil
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
