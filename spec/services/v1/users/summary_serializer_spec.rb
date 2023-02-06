require 'rails_helper'

describe V1::Users::SummarySerializer do
  include ActiveModel::Serializers
  include ActiveModel::Serializers::JSON

  describe 'fields' do
    let(:user) { create(:public_user) }

    let(:serialized) { V1::Users::SummarySerializer.new(user, scope: { user: user }).serializable_hash }

    it { expect(serialized).to have_key(:id) }
    it { expect(serialized).to have_key(:display_name) }
    it { expect(serialized).to have_key(:avatar_url) }
    it { expect(serialized).to have_key(:meetings_count) }
    it { expect(serialized).to have_key(:chat_messages_count) }
    it { expect(serialized).to have_key(:outing_participations_count) }
    it { expect(serialized).to have_key(:neighborhood_participations_count) }
    it { expect(serialized).to have_key(:recommandations) }
    it { expect(serialized).to have_key(:congratulations) }
    it { expect(serialized).to have_key(:moderator) }

    describe 'meetings_count' do
      context 'no outing, no action' do
        it { expect(serialized[:meetings_count]).to eq(0) }
      end

      context 'no outing, one action without outcome' do
        let!(:entourage) { create(:entourage, user: user, status: :closed) }

        it { expect(serialized[:meetings_count]).to eq(0) }
      end

      context 'no outing, one action with outcome Oui' do
        let!(:entourage) { create(:entourage, :outcome_oui, user: user, status: :closed) }

        it { expect(serialized[:meetings_count]).to eq(1) }
      end

      context 'no outing, one action with outcome Oui but not user creator' do
        let!(:entourage) { create(:entourage, :outcome_oui, status: :closed) }

        it { expect(serialized[:meetings_count]).to eq(0) }
      end

      context 'no outing, one action with outcome Non' do
        let!(:entourage) { create(:entourage, :outcome_non, user: user, status: :closed) }

        it { expect(serialized[:meetings_count]).to eq(0) }
      end

      context 'no outing, one action with invalid outcome Oui' do
        let!(:entourage) { create(:entourage, :outcome_oui, user: user, status: :open) }

        it { expect(serialized[:meetings_count]).to eq(0) }
      end
    end
  end
end
