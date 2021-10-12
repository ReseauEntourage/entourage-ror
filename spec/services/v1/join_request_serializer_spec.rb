require 'rails_helper'

describe V1::JoinRequestSerializer do
  include ActiveModel::Serializers
  include ActiveModel::Serializers::JSON

  describe 'author' do
    let(:partner) { FactoryBot.create(:partner) }
    let(:user) { FactoryBot.create(:public_user, partner: partner) }
    let(:join_request) { FactoryBot.create(:join_request, user: user) }
    let(:serialization) { V1::JoinRequestSerializer.new(join_request)}

    it { expect(serialization.attributes).to have_key(:id) }
    it { expect(serialization.attributes).to have_key(:display_name) }
    it { expect(serialization.attributes).to have_key(:role) }
    it { expect(serialization.attributes).to have_key(:group_role) }
    it { expect(serialization.attributes).to have_key(:community_roles) }
    it { expect(serialization.attributes).to have_key(:status) }
    it { expect(serialization.attributes).to have_key(:message) }
    it { expect(serialization.attributes).to have_key(:requested_at) }
    it { expect(serialization.attributes).to have_key(:avatar_url) }
    it { expect(serialization.attributes).to have_key(:partner) }
    it { expect(serialization.attributes).to have_key(:partner_role_title) }
    it { expect(serialization.attributes).to have_key(:partner_with_current_user) }

    context 'user with no partner' do
      it { expect(serialization.partner_with_current_user).to be(false) }
    end

    context 'user with partner' do
      let!(:following) { FactoryBot.create(:following, partner: partner, user: user )}

      it { expect(serialization.partner_with_current_user).to be(true) }
    end
  end
end
