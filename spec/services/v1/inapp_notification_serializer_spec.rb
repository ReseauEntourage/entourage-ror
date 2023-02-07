require 'rails_helper'

describe V1::InappNotificationSerializer do
  include ActiveModel::Serializers
  include ActiveModel::Serializers::JSON

  describe 'fields' do
    let(:user) { create(:public_user, avatar_key: "avatar_user") }
    let(:sender) { create(:public_user, avatar_key: "avatar_sender") }
    let(:inapp_notification) { create(:inapp_notification, user: user, sender: sender) }

    let(:serialized) { V1::InappNotificationSerializer.new(inapp_notification).serializable_hash }

    it { expect(serialized).to have_key(:instance) }
    it { expect(serialized).to have_key(:instance_id) }
    it { expect(serialized).to have_key(:created_at) }

    context 'values' do
      it { expect(serialized[:instance]).to eq('neighborhood') }
      it { expect(serialized[:instance_id]).to eq(inapp_notification.instance_id) }
    end

    context 'neighborhood_post' do
      let(:inapp_notification) { create(:inapp_notification, :neighborhood_post, user: user, sender: sender, context: :chat_message_on_create) }

      before { UserServices::Avatar.any_instance.stub(:thumbnail_url) { "https://foo.bar" }}

      it { expect(serialized[:instance]).to eq('neighborhood_post') }
      it { expect(serialized[:image_url]).to eq("https://foo.bar") }
    end
  end
end
