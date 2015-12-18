require 'rails_helper'

describe IosNotificationService, type: :service do
  describe '#send_notification' do
    let!(:sender) { 'sender' }
    let!(:object) { 'object' }
    let!(:content) { 'content' }
    let!(:device_ids) { ['1ea4b458607094b493b8a4be2712ee6b0a1c3cc9af6d7db9caabec6a10994a20', '1ea4b458607094b493b8a4be2712ee6b0a1c3cc9af6d7db9caabec6a10994a20', '1ea4b458607094b493b8a4be2712ee6b0a1c3cc9af6d7db9caabec6a10994a20'] }
    let!(:notification_pusher) { spy('notification_pusher') }
    context 'ios app is present' do
      let!(:ios_app) { FactoryGirl.create :ios_app }
      subject! { IosNotificationService.new(notification_pusher).send_notification(sender, object, content, device_ids) }
      it { expect(Rpush::Apns::Notification.count).to eq(3) }
      it { expect(Rpush::Apns::Notification.last.app).to eq(ios_app) }
      it { expect(Rpush::Apns::Notification.last.device_token).to eq(device_ids.last) }
      it { expect(Rpush::Apns::Notification.last.data).to eq({ "sender" => sender, "object" => object, "content" => content }) }
      it { expect(notification_pusher).to have_received(:push).with(no_args) }
    end
    context 'ios app is absent' do
      it "raise an error" do
        expect {
          IosNotificationService.new(notification_pusher).send_notification(sender, object, content, device_ids)
        }.to raise_error
      end
    end
  end
end