require 'rails_helper'

describe SmsNotificationService do
  describe '#send_notification' do
    let!(:message) { 'message' }
    let!(:phone_number) { 'phone number' }
    let!(:sinch_mock) { double('sinch') }
    let!(:sms_notification_service) { SmsNotificationService.new sinch_mock }
  
    context "api key and secret are provided as env variables" do
      before do
        ENV["SINCH_API_KEY"] = "key"
        ENV["SINCH_API_SECRET"] = "secret"
        # needed since "send" is an object method
        sinch_mock.stub(:send)
        sms_notification_service.send_notification(phone_number, message)
      end
      it { expect(sinch_mock).to have_received(:send).with('key', 'secret', message, phone_number) }
    end
    
    context "api key and secret are not provided as env variables" do
      before do
        ENV.delete("SINCH_API_KEY")
        ENV.delete("SINCH_API_SECRET")
        Rails.logger.stub(:warn)
        sms_notification_service.send_notification(phone_number, message)
      end
      it { expect(Rails.logger).to have_received(:warn).with('No SMS has been sent. Please provide SINCH_API_KEY and SINCH_API_SECRET environment variables') }
    end
  end
end