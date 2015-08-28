require 'rails_helper'

describe IosNotificationService, type: :service do
  describe '#send_notification' do
    let!(:sender) { 'sender' }
    let!(:object) { 'object' }
    let!(:content) { 'content' }
    let!(:device_ids) { ['id1', 'id2', 'id3'] }
    let!(:notification_pusher) { spy('notification_pusher') }
    context 'android app is present' do
      # Awaiting Ios app support to be able to mock the app
    end
    context 'android app is absent' do
      before { Rails.logger.stub(:warn) }
      subject! { IosNotificationService.new(notification_pusher).send_notification(sender, object, content, device_ids) }
      it { expect(Rails.logger).to have_received(:warn).with('No IOS notification has been sent. Please save a Rpush::Apns::App in database'.red) }
    end
  end
end