class TestChannel < ApplicationCable::Channel
  def subscribed
    stream_from "test_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def ping(data)
    ActionCable.server.broadcast("test_channel", { message: "pong", received: data })
  end
end
