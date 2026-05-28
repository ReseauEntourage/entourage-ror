class NotificationChannel < ApplicationCable::Channel
  def subscribed
    reject and return unless current_user

    stream_from "notifications_#{current_user.id}"
  end

  def unsubscribed
    stop_all_streams
  end

  def self.broadcast_to_user(user, data)
    return unless user&.id
    ActionCable.server.broadcast("notifications_#{user.id}", data)
  end
end
