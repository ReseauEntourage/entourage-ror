require 'rails_helper'

describe V1::InappNotificationSerializer do
  include ActiveModel::Serializers
  include ActiveModel::Serializers::JSON

  describe 'fields' do
    let(:user) { FactoryBot.create(:public_user) }
    let(:inapp_notification) { FactoryBot.create(:inapp_notification, user: user) }

    let(:serialized) { V1::InappNotificationSerializer.new(inapp_notification).serializable_hash }

    it { expect(serialized).to have_key(:instance) }
    it { expect(serialized).to have_key(:instance_id) }
    it { expect(serialized).to have_key(:created_at) }

    context 'values' do
      it { expect(serialized[:instance]).to eq('neighborhood') }
      it { expect(serialized[:instance_id]).to eq(inapp_notification.instance_id) }
    end
  end
end
