require 'rails_helper'

describe V1::NeighborhoodSerializer do
  include ActiveModel::Serializers
  include ActiveModel::Serializers::JSON

  describe 'fields' do
    let(:user) { FactoryBot.create(:public_user) }
    let(:neighborhood) { FactoryBot.create(:neighborhood, user: user) }

    let(:subject) { V1::NeighborhoodSerializer.new(neighborhood).attributes }
    let(:serialized) { V1::NeighborhoodSerializer.new(neighborhood).serializable_hash }

    it { expect(serialized).to have_key(:id) }
    it { expect(serialized).to have_key(:name) }
    it { expect(serialized).to have_key(:members_count) }
    it { expect(serialized).to have_key(:image_url) }
    it { expect(serialized).to have_key(:interests) }
    it { expect(serialized).to have_key(:ethics) }
    it { expect(serialized).to have_key(:future_outings_count) }

    it { expect(serialized).to have_key(:members) }

    context 'values' do
      it { expect(serialized[:name]).to eq('Foot Paris 17è') }
      it { expect(serialized[:interests]).to eq(['sport']) }
    end
  end
end
