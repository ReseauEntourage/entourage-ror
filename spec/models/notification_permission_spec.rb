require 'rails_helper'

RSpec.describe NotificationPermission, :type => :model do
  it { should validate_presence_of(:user) }

  describe 'notify?' do
    let(:notification_permission) { FactoryBot.create :notification_permission, permissions: permissions }
    let(:permissions) { {} }
    let(:instance) { nil }
    let(:instance_id) { nil }

    subject { notification_permission.notify?(instance, instance_id) }

    context 'unknown instance' do
      let(:instance) { :foo }

      it { expect(subject).to eq(false) }
    end

    context 'undefined instance return true' do
      let(:permissions) { {} }
      let(:instance) { :neighborhood }

      it { expect(subject).to eq(true) }
    end

    context 'known instance return true' do
      let(:permissions) { { neighborhood: true } }
      let(:instance) { :neighborhood }

      it { expect(subject).to eq(true) }
    end

    context 'known instance return false' do
      let(:permissions) { { neighborhood: false } }
      let(:instance) { :neighborhood }

      it { expect(subject).to eq(false) }
    end

    context 'chat_message instance return true' do
      let(:conversation) { create :conversation }
      let(:instance) { :conversation }
      let(:instance_id) { conversation.id }

      it { expect(subject).to eq(true) }
    end

    context 'chat_message instance return false' do
      let(:permissions) { { chat_message: false, action: true } }

      let(:conversation) { create :conversation }
      let(:instance) { :conversation }
      let(:instance_id) { conversation.id }

      it { expect(subject).to eq(false) }
    end

    context 'chat_message instance on action return true' do
      let(:permissions) { { chat_message: false, action: true } }

      let(:entourage) { create :entourage }
      let(:instance) { :conversation }
      let(:instance_id) { entourage.id }

      it { expect(subject).to eq(true) }
    end
  end
end
