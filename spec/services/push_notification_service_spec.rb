require 'rails_helper'

describe PushNotificationService, type: :service do
  describe '#send_notification' do
    let!(:android_notification_service) { spy('android_notification_service') }
    let!(:ios_notification_service) { spy('ios_notification_service') }
    let!(:user1) { create :user, device_type: :android, device_id: 'device id 1' }
    let!(:user2) { create :user, device_type: :android, device_id: 'device id 2' }
    let!(:user3) { create :user, device_type: :android, device_id: nil }
    let!(:user4) { create :user, device_type: :ios, device_id: 'device id 3' }
    let!(:user5) { create :user, device_type: :ios, device_id: 'device id 4' }
    let!(:user6) { create :user, device_type: :ios, device_id: nil }
    let!(:user7) { create :user, device_type: nil, device_id: nil }
    let!(:sender) { 'sender' }
    let!(:object) { 'object' }
    let!(:content) { 'content' }
    subject! { PushNotificationService.new(android_notification_service, ios_notification_service).send_notification(sender, object, content, User.all) }
    it { expect(android_notification_service).to have_received(:send_notification).with(sender, object, content, [user1.device_id, user2.device_id]) }
    it { expect(ios_notification_service).to have_received(:send_notification).with(sender, object, content, [user4.device_id, user5.device_id]) }
  end
end
