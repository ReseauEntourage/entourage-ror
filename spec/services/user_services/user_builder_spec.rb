require 'rails_helper'

describe UserServices::ProUserBuilder do

  describe 'create' do
    before { UserServices::SmsCode.any_instance.stub(:code) { "123456" }}
    let(:params) do FactoryBot.build(:user).attributes.select {|k, v| ["email", "first_name", "last_name", "phone"].include?(k) } end
    let(:organization) { FactoryBot.build(:organization) }

    it 'sends sms with created code' do
      expect_any_instance_of(UserServices::SMSSender).to receive(:send_welcome_sms).with("123456").once
      UserServices::ProUserBuilder.new(params: params, organization: organization).create(send_sms: true)
    end

    it "doesn't send sms with created code" do
      expect_any_instance_of(UserServices::SMSSender).to receive(:send_welcome_sms).never
      UserServices::ProUserBuilder.new(params: params, organization: organization).create(send_sms: false)
    end
  end
end
