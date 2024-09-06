require 'rails_helper'

describe PushNotificationService, type: :service do
  let!(:notification_service) { spy('notification_service') }
  let!(:user) { FactoryBot.create(:pro_user) }
  let!(:sender) { 'sender' }
  let!(:object) { PushNotificationTrigger::I18nStruct.new(text: 'object') }
  let!(:content) { PushNotificationTrigger::I18nStruct.new(text: 'content') }

  before do
    # Stub la méthode privée pour qu'elle retourne notre spy
    allow_any_instance_of(PushNotificationService).to receive(:notification_service).and_return(notification_service)
  end

  describe '#send_notification' do
    let!(:user_app1) { FactoryBot.create :user_application, device_family: UserApplication::ANDROID, push_token: 'token 1' }
    let!(:user_app2) { FactoryBot.create :user_application, device_family: UserApplication::IOS, push_token: 'token 2' }

    subject! { PushNotificationService.new.send_notification(sender, object, content, User.all, :outing, :foo) }

    it { expect(notification_service).to have_received(:send_notification).with(sender, 'object', 'content', user_app1.push_token, user.community.slug, {}, 0) }
    it { expect(notification_service).to have_received(:send_notification).with(sender, 'object', 'content', user_app2.push_token, user.community.slug, {}, 0) }
  end

  describe '#send_notification_android_only' do
    let!(:user_app) { FactoryBot.create :user_application, device_family: UserApplication::ANDROID, push_token: 'token 1' }

    subject! { PushNotificationService.new.send_notification(sender, object, content, User.all, :outing, :foo) }

    it { expect(notification_service).to have_received(:send_notification).with(sender, 'object', 'content', user_app.push_token, user.community.slug, {}, 0) }
  end

  describe '#send_notification_ios_only' do
    let!(:user_app) { FactoryBot.create :user_application, device_family: UserApplication::IOS, push_token: 'token 2' }

    subject! { PushNotificationService.new.send_notification(sender, object, content, User.all, :outing, :foo) }

    it { expect(notification_service).to have_received(:send_notification).with(sender, 'object', 'content', user_app.push_token, user.community.slug, {}, 0) }
  end

  describe '#send_notification_4ios_tokens' do
    let!(:user_app1) { FactoryBot.create :user_application, device_family: UserApplication::IOS, push_token: 'token 1' }
    let!(:user_app2) { FactoryBot.create :user_application, device_family: UserApplication::IOS, push_token: 'token 2' }
    let!(:user_app3) { FactoryBot.create :user_application, device_family: UserApplication::IOS, push_token: 'token 3' }
    let!(:user_app4) { FactoryBot.create :user_application, device_family: UserApplication::IOS, push_token: 'token 4' }

    subject! { PushNotificationService.new.send_notification(sender, object, content, User.all, :outing, :foo) }

    it { expect(notification_service).to have_received(:send_notification).with(sender, 'object', 'content', user_app4.push_token, user.community.slug, {}, 0) }
    it { expect(notification_service).to have_received(:send_notification).with(sender, 'object', 'content', user_app2.push_token, user.community.slug, {}, 0) }
    it { expect(notification_service).to have_received(:send_notification).with(sender, 'object', 'content', user_app3.push_token, user.community.slug, {}, 0) }
  end

  describe '#send_notification do not send to blocked users' do
    let!(:android_user) { FactoryBot.create :user_application, device_family: UserApplication::ANDROID, push_token: 'token 1' }
    let!(:ios_user) { FactoryBot.create :user_application, device_family: UserApplication::IOS, push_token: 'token 2' }

    context 'with valid users' do
      subject! {
        PushNotificationService.new.send_notification(sender, object, content, [android_user.user, ios_user.user], :outing, :foo)
      }

      it { expect(notification_service).to have_received(:send_notification).with(sender, 'object', 'content', android_user.push_token, android_user.user.community.slug, {}, 0) }
      it { expect(notification_service).to have_received(:send_notification).with(sender, 'object', 'content', ios_user.push_token, ios_user.user.community.slug, {}, 0) }
    end

    context 'with blocked users' do
      before {
        android_user.user.update_attribute(:validation_status, :blocked)
        ios_user.user.update_attribute(:validation_status, :blocked)
      }

      subject! {
        PushNotificationService.new.send_notification(sender, object, content, [android_user.user, ios_user.user], :outing, :foo)
      }

      it { expect(notification_service).not_to have_received(:send_notification) }
    end
  end
end
