require 'rails_helper'

describe IosNotificationService do
  describe '#send_notification' do
    before { Rpush.stub(:push) { nil } }

    let(:service) { IosNotificationService.new }

    context 'ios app is present' do
      let!(:ios_app) { FactoryBot.create(:ios_app, name: 'entourage') }
      before { service.send_notification("sender", "object", "content", '1ea4b458607094b493b8a4be2712ee6b0a1c3cc9af6d7db9caabec6a10994a20', 'entourage') }
      it { expect(Rpush::Apnsp8::Notification.count).to eq(1) }
      it { expect(Rpush::Apnsp8::Notification.last.app).to eq(ios_app) }
      it { expect(Rpush::Apnsp8::Notification.first.device_token).to eq('1ea4b458607094b493b8a4be2712ee6b0a1c3cc9af6d7db9caabec6a10994a20') }
      it { expect(Rpush::Apnsp8::Notification.last.device_token).to eq('1ea4b458607094b493b8a4be2712ee6b0a1c3cc9af6d7db9caabec6a10994a20') }
      it { expect(Rpush::Apnsp8::Notification.last.data).to eq({ "sender" => "sender", "object" => "object", "content" => {"message"=>"content", "extra"=>{}} }) }
    end

    context 'ios app is absent' do
      it "raises exception" do
        expect {
          service.send_notification("sender", "object", "content", ["device_id_1", "device_id_2"])
        }.to raise_error(ArgumentError)
        expect(Rpush::Apnsp8::Notification.count).to eq(0)
      end
    end
  end

  describe 'APNS updates' do
    let(:service) { IosNotificationService.new }
    let(:user) { FactoryBot.create(:pro_user) }
    context 'unregistered id received from APNS' do
      let!(:user_application) { FactoryBot.create(:user_application, user: user, push_token: "token", device_family: UserApplication::IOS, version: "1.0") }
      let!(:user_application2) { FactoryBot.create(:user_application, user: user, push_token: "token2", device_family: UserApplication::IOS, version: "1.1") }
      let!(:user_application3) { FactoryBot.create(:user_application, user: user, push_token: "token3", device_family: UserApplication::IOS, version: "1.2") }
      let!(:user_application4) { FactoryBot.create(:user_application, user: user, push_token: "token4", device_family: UserApplication::ANDROID, version: "2.2") }
      before { service.unregister_token("token3") }
      it { expect(user.user_applications.count).to eq(3) }
      it { expect(user.user_applications.last.push_token).to eq("token4") }
    end

    context 'unregistering unkown id received from APNS' do
      let!(:user_application) { FactoryBot.create(:user_application, user: user, push_token: "token", device_family: UserApplication::IOS, version: "1.0") }
      let!(:user_application2) { FactoryBot.create(:user_application, user: user, push_token: "token2", device_family: UserApplication::IOS, version: "1.1") }
      let!(:user_application3) { FactoryBot.create(:user_application, user: user, push_token: "token3", device_family: UserApplication::IOS, version: "1.2") }
      before { service.unregister_token("token4") }
      it { expect(user.user_applications.count).to eq(3) }
    end
  end
end
