class PingChannel < ApplicationCable::Channel
  def subscribed
    stream_from "ping_channel"
  end

  def ping
    ActionCable.server.broadcast("ping_channel", { message: "pong", time: Time.now })
  end
end
