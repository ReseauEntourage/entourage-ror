require 'rails_helper'

describe AndroidNotificationService do
  describe '#send_notification' do
    let!(:android_app) { FactoryGirl.create :android_app }
    let!(:sender) { 'sender' }
    let!(:object) { 'object' }
    let!(:content) { 'content' }
    let!(:device_ids) { ['id1', 'id2', 'id3'] }
    let!(:notification_pusher) { spy('notification_pusher') }
    subject! { AndroidNotificationService.new(notification_pusher).send_notification(sender, object, content, device_ids) }
    it { expect(Rpush::Gcm::Notification.last.app).to eq(android_app) }
    it { expect(Rpush::Gcm::Notification.last.registration_ids).to eq(device_ids) }
    it { expect(Rpush::Gcm::Notification.last.data).to eq({ "sender" => sender, "object" => object, "content" => content }) }
    it { expect(notification_pusher).to have_received(:push).with(no_args) }
  end
end