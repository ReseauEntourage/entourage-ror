require 'rails_helper'

describe AndroidNotificationService do
  describe '#send_notification' do
    let!(:sender) { 'sender' }
    let!(:object) { 'object' }
    let!(:content) { 'content' }
    let!(:device_ids) { ['id1', 'id2', 'id3'] }
    let!(:notification_pusher) { spy('notification_pusher') }
    context 'android app is present' do
      let!(:android_app) { FactoryGirl.create :android_app }
      subject! { AndroidNotificationService.new(notification_pusher).send_notification(sender, object, content, device_ids) }
      it { expect(Rpush::Gcm::Notification.last.app).to eq(android_app) }
      it { expect(Rpush::Gcm::Notification.last.registration_ids).to eq(device_ids) }
      it { expect(Rpush::Gcm::Notification.last.data).to eq({ "sender" => sender, "object" => object, "content" => content }) }
      it { expect(notification_pusher).to have_received(:push).with(no_args) }
    end
    context 'android app is absent' do
      before { Rails.logger.stub(:warn) }
      subject! { AndroidNotificationService.new(notification_pusher).send_notification(sender, object, content, device_ids) }
      it { expect(Rails.logger).to have_received(:warn).with('No android notification has been sent. Please save a Rpush::Gcm::App in database'.red) }
    end
  end
end