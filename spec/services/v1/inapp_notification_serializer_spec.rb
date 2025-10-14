require 'rails_helper'

describe V1::InappNotificationSerializer do
  include ActiveModel::Serializers
  include ActiveModel::Serializers::JSON

  describe 'fields' do
    let(:user) { create(:public_user, avatar_key: 'avatar_user') }
    let(:sender) { create(:public_user, avatar_key: 'avatar_sender') }
    let(:inapp_notification) { create(:inapp_notification, user: user, sender: sender) }

    let(:serialized) { V1::InappNotificationSerializer.new(inapp_notification).serializable_hash }

    it { expect(serialized).to have_key(:instance) }
    it { expect(serialized).to have_key(:instance_id) }
    it { expect(serialized).to have_key(:created_at) }

    before { UserServices::Avatar.any_instance.stub(:thumbnail_url) { 'https://foo.bar' }}

    context 'values' do
      it { expect(serialized[:instance]).to eq('neighborhood') }
      it { expect(serialized[:instance_id]).to eq(inapp_notification.instance_id) }
    end

    # post in neighborhood
    context 'neighborhood_post' do
      let(:inapp_notification) { create(:inapp_notification, :neighborhood_post, user: user, sender: sender, context: :chat_message_on_create) }

      it { expect(serialized[:instance]).to eq('neighborhood_post') }
      it { expect(serialized[:image_url]).to eq('https://foo.bar') }
    end

    # create join_request (outing, neighborhood)
    context 'join_request_on_create' do
      let(:inapp_notification) { create(:inapp_notification, :user, user: user, sender: sender, context: :join_request_on_create) }

      it { expect(serialized[:instance]).to eq('user') }
      it { expect(serialized[:image_url]).to eq('https://foo.bar') }
    end

    # update join_request (outing, neighborhood)
    context 'join_request_on_update' do
      let(:inapp_notification) { create(:inapp_notification, :user, user: user, sender: sender, context: :join_request_on_update) }

      it { expect(serialized[:instance]).to eq('user') }
      it { expect(serialized[:image_url]).to eq('https://foo.bar') }
    end

    # associate outing to neighborhood
    context 'neighborhoods_entourage_on_create' do
      let(:inapp_notification) { create(:inapp_notification, :outing, user: user, sender: sender, context: :neighborhoods_entourage_on_create) }

      it { expect(serialized[:instance]).to eq('outing') }
      it { expect(serialized[:image_url]).to be_nil }
    end

    # update outing
    context 'outing_on_update' do
      let(:inapp_notification) { create(:inapp_notification, :outing, user: user, sender: sender, context: :outing_on_update) }

      it { expect(serialized[:instance]).to eq('outing') }
      it { expect(serialized[:image_url]).to be_nil }
    end
  end
end
