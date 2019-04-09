require 'rails_helper'
include AuthHelper

RSpec.describe Api::V0::MessagesController, :type => :controller do

  describe 'create' do
    context "valid message" do
      before { post 'create', {message: {content: "abcf", first_name: "john", last_name: "doe", email: "some@mail.com"} } }
      it { expect(response.status).to eq(201) }
      it { expect(Message.last.content).to eq("abcf") }
      it { expect(Message.last.first_name).to eq("john") }
      it { expect(Message.last.last_name).to eq("doe") }
      it { expect(Message.last.email).to eq("some@mail.com") }
    end

    context "invalid message" do
      subject { post 'create', {message: {content: ""} } }
      it { expect(lambda { subject }).to change {Message.count}.by(0) }
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
