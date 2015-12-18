require 'rails_helper'

describe UserServices::SMSSender do
  
  describe 'send_welcome_sms!' do
    let(:user) { FactoryGirl.create(:user, sms_code: "123456") }
    let(:sender) { UserServices::SMSSender.new(user: user) }

    it "regenerates user sms code" do
      expect {
        sender.send_welcome_sms!
      }.to change {user.sms_code}
    end
  end
end