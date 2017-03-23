require 'rails_helper'

describe PushNotificationService, type: :service do
  describe '#send_notification' do
    let!(:android_notification_service) { spy('android_notification_service') }
    let!(:ios_notification_service) { spy('ios_notification_service') }
    let!(:user_app1) { FactoryGirl.create :user_application, device_family: UserApplication::ANDROID, push_token: 'token 1' }
    let!(:user_app2) { FactoryGirl.create :user_application, device_family: UserApplication::IOS, push_token: 'token 2' }
    let!(:user) { FactoryGirl.create(:pro_user) }
    let!(:sender) { 'sender' }
    let!(:object) { 'object' }
    let!(:content) { 'content' }
    subject! { PushNotificationService.new(android_notification_service, ios_notification_service).send_notification(sender, object, content, User.all) }
    it { expect(android_notification_service).to have_received(:send_notification).with(sender, object, content, match_array([user_app1.push_token]), {}) }
    it { expect(ios_notification_service).to have_received(:send_notification).with(sender, object, content, 0, match_array([user_app2.push_token]), {}) }
  end
end
