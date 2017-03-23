require 'rails_helper'

describe IosNotificationService do
  describe '#send_notification' do
    let(:service) { IosNotificationService.new }

    context 'android app is present' do
      let!(:ios_app) { FactoryGirl.create(:ios_app, name: 'entourage') }
      before { service.send_notification("sender", "object", "content", 10, ['1ea4b458607094b493b8a4be2712ee6b0a1c3cc9af6d7db9caabec6a10994a20', '1ea4b458607094b493b8a4be2712ee6b0a1c3cc9af6d7db9caabec6a10994a20']) }
      it { expect(Rpush::Apns::Notification.count).to eq(2) }
      it { expect(Rpush::Apns::Notification.last.app).to eq(ios_app) }
      it { expect(Rpush::Apns::Notification.first.device_token).to eq('1ea4b458607094b493b8a4be2712ee6b0a1c3cc9af6d7db9caabec6a10994a20') }
      it { expect(Rpush::Apns::Notification.last.device_token).to eq('1ea4b458607094b493b8a4be2712ee6b0a1c3cc9af6d7db9caabec6a10994a20') }
      it { expect(Rpush::Apns::Notification.last.data).to eq({ "sender" => "sender", "object" => "object", "content" => {"message"=>"content", "extra"=>{}} }) }
      it { expect(Rpush::Apns::Notification.first.badge).to eq(10) }
      it { expect(Rpush::Apns::Notification.last.badge).to eq(10) }
    end

    context 'android app is absent' do
      it "raises exception" do
        expect {
          service.send_notification("sender", "object", "content", 10, ["device_id_1", "device_id_2"])
        }.to raise_error
        expect(Rpush::Apns::Notification.count).to eq(0)
      end
    end
  end
end