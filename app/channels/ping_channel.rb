class PingChannel < ApplicationCable::Channel
  def subscribed
    stream_from "ping_channel"
  end
end
