require 'rails_helper'

RSpec.describe TestChannel, type: :channel do
  it "successfully subscribes" do
    subscribe
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from("test_channel")
  end

  it "broadcasts pong when ping is received" do
    subscribe
    expect {
      perform :ping, { "test" => "data" }
    }.to have_broadcasted_to("test_channel").with(hash_including(message: "pong"))
  end
end
