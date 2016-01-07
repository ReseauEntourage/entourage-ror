require 'rails_helper'

describe UserServices::UserBuilder do
  
  describe 'create' do
    before { UserServices::UserBuilder.stub(:sms_code) { "123456" }}
    let(:params) do FactoryGirl.build(:user).attributes.select {|k, v| ["email", "first_name", "last_name", "phone"].include?(k) } end
    let(:organization) { FactoryGirl.build(:organization) }

    it 'sends sms with created code' do
      expect_any_instance_of(UserServices::SMSSender).to receive(:send_welcome_sms).with("123456").once
      UserServices::UserBuilder.new(params: params, organization: organization).create(send_sms: true)
    end

    it "doesn't send sms with created code" do
      expect_any_instance_of(UserServices::SMSSender).to receive(:send_welcome_sms).never
      UserServices::UserBuilder.new(params: params, organization: organization).create(send_sms: false)
    end
  end
end