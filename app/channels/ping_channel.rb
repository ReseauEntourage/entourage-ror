class PingChannel < ApplicationCable::Channel
  def subscribed
    puts "[ActionCable] Client subscribed to ping_channel"
    stream_from "ping_channel"
  end
end
