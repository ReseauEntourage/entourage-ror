require 'rails_helper'

describe IosNotificationService do
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
