require 'rails_helper'
include AuthHelper

describe MessagesController do

  let(:user) { FactoryGirl.create(:user, token: "foobar") }

  describe 'create' do
    context "valid message" do
      subject { post 'create', {message: {content: "abcf"}, token: user.token } }
      it { expect(lambda { subject }).to change {Message.count}.by(1) }
      it "return 200" do
        subject
        expect(response.status).to eq(201)
      end
    end

    context "invalid message" do
      subject { post 'create', {message: {content: ""}, token: user.token } }
      it { expect(lambda { subject }).to change {Message.count}.by(0) }
      it "returns 400" do
        subject
        expect(response.status).to eq(400)
      end

      it "returns error mesage" do
        subject
        resp = JSON.parse(response.body)
        expect(resp["errors"]).to eq(["Content can't be blank"])
      end
    end
  end
end