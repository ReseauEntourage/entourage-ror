require 'rails_helper'

describe V1::NeighborhoodSerializer do
  include ActiveModel::Serializers
  include ActiveModel::Serializers::JSON

  describe 'fields' do
    let(:user) { FactoryBot.create(:public_user) }
    let(:neighborhood) { FactoryBot.create(:neighborhood, user: user) }
    let(:subject) { V1::NeighborhoodSerializer.new(neighborhood).attributes }

    it { expect(subject).to have_key(:id) }
    it { expect(subject).to have_key(:name) }
    it { expect(subject).to have_key(:members_count) }
    it { expect(subject).to have_key(:photo_url) }
    it { expect(subject).to have_key(:interests) }
    it { expect(subject).to have_key(:members) }
    it { expect(subject).to have_key(:ethics) }
    it { expect(subject).to have_key(:past_events_count) }
    it { expect(subject).to have_key(:future_events_count) }
    it { expect(subject).to have_key(:has_ongoing_event) }

    context 'values' do
      it { expect(subject[:name]).to eq('Foot Paris 17è') }
      it { expect(subject[:interests]).to eq(['sport']) }
    end
  end
end
