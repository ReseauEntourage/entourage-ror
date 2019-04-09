require 'rails_helper'

describe SmsNotificationService do
  describe '#send_notification' do
    let!(:message) { 'message' }
    let!(:phone_number) { 'phone number' }
    let!(:sms_type) { 'welcome' }
    let!(:sinch_mock) { double('sinch') }
    let!(:sms_notification_service) { SmsNotificationService.new sinch_mock }
    # create a stubbed client instance (mock the one in our code), and stub data
    let(:stub_client) { Aws::SNS::Client.new(stub_responses: true) }

    context "sinch as sms provider and api key and secret are provided as env variables" do
      before do
        ENV["SMS_PROVIDER"] = "SINCH"
        ENV["SINCH_API_KEY"] = "key"
        ENV["SINCH_API_SECRET"] = "secret"
        # needed since "send" is an object method
        sinch_mock.stub(:send)
        sms_notification_service.send_notification(phone_number, message, sms_type)
      end
      it { expect(sinch_mock).to have_received(:send).with('key', 'secret', message, phone_number) }
    end

    context "aws as sms provider and api key and secret are provided as env variables" do
      before do
        ENV["SMS_PROVIDER"] = "AWS"
        ENV["SMS_SENDER_NAME"] = "Entourage"
        # intercept the AWS client’s constructor and substitute our stub client
        expect(Aws::SNS::Client).to receive(:new).and_return(stub_client)
        stub_client.stub(:publish)
        sms_notification_service.send_notification(phone_number, message, sms_type)
      end
      it { expect(stub_client).to have_received(:publish).with({phone_number: phone_number, message: message}) }
    end

    context "sinch as sms provider and api key and secret are not provided as env variables" do
      before do
        ENV["SMS_PROVIDER"] = "SINCH"
        ENV.delete("SINCH_API_KEY")
        ENV.delete("SINCH_API_SECRET")
        Rails.logger.stub(:warn)
        sms_notification_service.send_notification(phone_number, message, sms_type)
      end
      it { expect(Rails.logger).to have_received(:warn).with('No SMS has been sent. Please provide SINCH_API_KEY and SINCH_API_SECRET environment variables') }
    end

    context "aws as sms provider and api key and secret are not provided as env variables" do
      before do
        ENV["SMS_PROVIDER"] = "AWS"
        ENV.delete("SMS_SENDER_NAME")
        Rails.logger.stub(:warn)
        sms_notification_service.send_notification(phone_number, message, sms_type)
      end
      it { expect(Rails.logger).to have_received(:warn).with('No SMS has been sent. Please provide SMS_SENDER_NAME environment variables') }
    end
  end
end
