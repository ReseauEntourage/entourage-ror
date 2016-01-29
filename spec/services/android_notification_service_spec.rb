require 'rails_helper'

describe AndroidNotificationService do
  describe '#send_notification' do
    let(:service) { AndroidNotificationService.new }

    context 'android app is present' do
      let!(:android_app) { FactoryGirl.create(:android_app, name: 'entourage') }
      before { service.send_notification("sender", "object", "content", ["device_id_1", "device_id_2"]) }
      it { expect(Rpush::Gcm::Notification.count).to eq(1) }
      it { expect(Rpush::Gcm::Notification.last.app).to eq(android_app) }
      it { expect(Rpush::Gcm::Notification.last.registration_ids).to eq(["device_id_1", "device_id_2"]) }
      it { expect(Rpush::Gcm::Notification.last.data).to eq({ "sender" => "sender", "object" => "object", "content" => "content" }) }
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
end