require 'rails_helper'

describe V1::EntourageSerializer do
  include ActiveModel::Serializers
  include ActiveModel::Serializers::JSON

  describe 'author partner' do
    let(:user) { FactoryBot.create(:public_user) }
    let(:partner) { FactoryBot.create(:partner) }
    let(:creator) { FactoryBot.create(:public_user, partner: partner) }
    let(:entourage) { FactoryBot.create(:entourage, user: creator) }
    let(:serialization) { V1::EntourageSerializer.new(entourage, scope: {
      user: user
    })}

    it { expect(serialization.author).to have_key(:id) }
    it { expect(serialization.author).to have_key(:display_name) }
    it { expect(serialization.author).to have_key(:avatar_url) }
    it { expect(serialization.author).to have_key(:partner) }
    it { expect(serialization.author).to have_key(:partner_role_title) }

    context 'user with no partner' do
      it { expect(serialization.author[:partner]).to have_key(:following) }
      it { expect(serialization.author[:partner][:following]).to be(false) }
    end

    context 'user with partner' do
      let!(:following) { FactoryBot.create(:following, partner: partner, user: user )}

      it { expect(serialization.author[:partner]).to have_key(:following) }
      it { expect(serialization.author[:partner][:following]).to be(true) }
    end
  end
end
