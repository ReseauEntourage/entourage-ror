require 'rails_helper'

describe SmsNotificationService do
  describe '#send_notification' do
    let!(:message) { 'message' }
    let!(:phone_number) { 'phone number' }
    let!(:sms_type) { 'welcome' }
    let!(:sms_notification_service) { SmsNotificationService.new}
    # create a stubbed client instance (mock the one in our code), and stub data
    let(:stub_client) { Aws::SNS::Client.new(stub_responses: true) }

    context 'api key and secret are provided as env variables' do
      before do
        ENV['SMS_PROVIDER'] = 'AWS'
        ENV['SMS_SENDER_NAME'] = 'Entourage'
        # intercept the AWS client’s constructor and substitute our stub client
        expect(Aws::SNS::Client).to receive(:new).and_return(stub_client)
        allow(stub_client).to receive(:publish).and_call_original
        sms_notification_service.send_notification(phone_number, message, sms_type)
      end
      it { expect(stub_client).to have_received(:publish).with(
        {
          phone_number: phone_number,
          message: message,
          message_attributes: {
            'AWS.SNS.SMS.SenderID' => {string_value: ENV['SMS_SENDER_NAME'], data_type: 'String'},
            'AWS.SNS.SMS.SMSType' => {string_value: 'Transactional', data_type: 'String'},
          }
        }
      )}
      it { expect(SmsDelivery.where(phone_number: phone_number, sms_type: sms_type, provider: 'AWS').last&.status).to eq 'Ok' }
    end

    context 'aws as sms provider and api key and secret are not provided as env variables' do
      before do
        ENV['SMS_PROVIDER'] = 'AWS'
        ENV.delete('SMS_SENDER_NAME')
        Rails.logger.stub(:warn)
        sms_notification_service.send_notification(phone_number, message, sms_type)
      end
      it { expect(Rails.logger).to have_received(:warn).with('No SMS has been sent. Please provide SMS_SENDER_NAME environment variables') }
    end
  end
end
