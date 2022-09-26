require 'rails_helper'

describe AndroidNotificationService do
  describe '#send_notification' do
    let(:service) { AndroidNotificationService.new }

    context 'android app is present' do
      let!(:android_app) { FactoryBot.create(:android_app, name: 'entourage') }
      before { service.send_notification("sender", "object", "content", ["device_id_1", "device_id_2"], 'entourage') }
      it { expect(Rpush::Gcm::Notification.count).to eq(1) }
      it { expect(Rpush::Gcm::Notification.last.app).to eq(android_app) }
      it { expect(Rpush::Gcm::Notification.last.registration_ids).to eq(["device_id_1", "device_id_2"]) }
      it { expect(Rpush::Gcm::Notification.last.data).to eq({ "sender" => "object", "object" => "object", "content" => {"message"=>"content", "extra"=>{}} }) }
    end

    context 'android app is absent' do
      it "raises exception" do
        expect {
          service.send_notification("sender", "object", "content", ["device_id_1", "device_id_2"])
        }.to raise_error
        expect(Rpush::Gcm::Notification.count).to eq(0)
      end
    end
  end

  describe 'FCM updates' do
    let(:service) { AndroidNotificationService.new }
    let(:user) { FactoryBot.create(:pro_user) }
    context 'update existing id by canonical id received from FCM' do
      let!(:user_application) { FactoryBot.create(:user_application, user: user, push_token: "old_token", device_family: UserApplication::ANDROID, version: "1.0") }
      before { service.update_canonical_id("old_token", "foobar") }
      it { expect(user.user_applications.count).to eq(1) }
      it { expect(user.user_applications.last.push_token).to eq("foobar") }
    end

    context 'update unknown id by canonical id received from FCM' do
      let!(:user_application) { FactoryBot.create(:user_application, user: user, push_token: "old_token", device_family: UserApplication::ANDROID, version: "1.0") }
      before { service.update_canonical_id("unknown_token", "foobar") }
      it { expect(user.user_applications.count).to eq(1) }
      it { expect(user.user_applications.last.push_token).to eq("old_token") }
    end

    context 'unregistered id received from FCM' do
      let!(:user_application) { FactoryBot.create(:user_application, user: user, push_token: "token", device_family: UserApplication::ANDROID, version: "1.0") }
      let!(:user_application1) { FactoryBot.create(:user_application, user: user, push_token: "token2", device_family: UserApplication::ANDROID, version: "1.1") }
      let!(:user_application2) { FactoryBot.create(:user_application, user: user, push_token: "token3", device_family: UserApplication::ANDROID, version: "1.2") }
      before { service.unregister_token("token3") }
      it { expect(user.user_applications.count).to eq(2) }
      it { expect(user.user_applications.last.push_token).to eq("token2") }
    end

    context 'unregistering unkown id received from FCM' do
      let!(:user_application) { FactoryBot.create(:user_application, user: user, push_token: "token", device_family: UserApplication::ANDROID, version: "1.0") }
      let!(:user_application2) { FactoryBot.create(:user_application, user: user, push_token: "token2", device_family: UserApplication::ANDROID, version: "1.1") }
      let!(:user_application3) { FactoryBot.create(:user_application, user: user, push_token: "token3", device_family: UserApplication::ANDROID, version: "1.2") }
      before { service.unregister_token("token4") }
      it { expect(user.user_applications.count).to eq(3) }
    end
  end
end
