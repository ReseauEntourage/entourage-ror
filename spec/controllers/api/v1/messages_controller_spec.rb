require 'rails_helper'
include AuthHelper

RSpec.describe Api::V1::MessagesController, :type => :controller do

  describe 'create' do
    context "valid message" do
      before { post 'create', params: { message: {content: "abcf", first_name: "john", last_name: "doe", email: "some@mail.com"} } }
      it { expect(response.status).to eq(201) }
      it { expect(Message.last.content).to eq("abcf") }
      it { expect(Message.last.first_name).to eq("john") }
      it { expect(Message.last.last_name).to eq("doe") }
      it { expect(Message.last.email).to eq("some@mail.com") }
      # we want it explicit that the route does not render a root serialized version of message
      it { expect(JSON.parse(response.body)).not_to have_key('message') }
      it { expect(JSON.parse(response.body)).to have_key('content') }
    end

    context "invalid message" do
      subject { post 'create', params: { message: {content: ""} } }
      it { expect { subject }.to change {Message.count}.by(0) }
      it "returns 400" do
        subject
        expect(response.status).to eq(400)
      end

      it "returns error mesage" do
        subject
        resp = JSON.parse(response.body)
        expect(resp["errors"]).to eq(["Content doit être rempli(e)"])
      end
    end
  end
end
