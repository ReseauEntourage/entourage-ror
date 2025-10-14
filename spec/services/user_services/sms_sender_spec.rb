require 'rails_helper'

describe UserServices::SmsSender do

  describe 'send_welcome_sms' do
    let(:user) { FactoryBot.create(:pro_user, sms_code: '123456') }
    let(:sender) { UserServices::SmsSender.new(user: user) }

    it "doesn't regenerate user sms code" do
      expect {
        sender.send_welcome_sms('123456')
      }.to_not change {user.sms_code}
    end
  end

  describe 'regenerate_sms!' do
    let(:user) { FactoryBot.create(:pro_user, sms_code: '123456') }
    let(:sender) { UserServices::SmsSender.new(user: user) }

    it "changes the user's sms code" do
      expect {
        sender.regenerate_sms!
      }.to change {user.sms_code}
    end

    it "resets the user's password" do
      expect {
        sender.regenerate_sms!
      }.to change {user.sms_code}
    end
  end
end
