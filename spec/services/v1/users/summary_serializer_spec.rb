require 'rails_helper'

describe V1::Users::SummarySerializer do
  include ActiveModel::Serializers
  include ActiveModel::Serializers::JSON

  describe 'fields' do
    let(:user) { create(:public_user) }

    let(:serialized) { V1::Users::SummarySerializer.new(user).serializable_hash }

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
    it { expect(serialized).to have_key(:referent_benevole) }
    it { expect(serialized).to have_key(:badge) }
    it { expect(serialized).to have_key(:engagement_segment) }
    it { expect(serialized).to have_key(:engagement_sub_segment) }
    it { expect(serialized).to have_key(:segment_computed_at) }

    describe 'engagement_segment' do
      context 'user has no computed segment yet' do
        it { expect(serialized[:engagement_segment]).to be_nil }
        it { expect(serialized[:engagement_sub_segment]).to be_nil }
        it { expect(serialized[:segment_computed_at]).to be_nil }
      end

      context 'user has a computed segment' do
        let!(:user_segment) do
          create(:user_segment, user: user, engagement_segment: 'Pilier', engagement_sub_segment: nil)
        end

        it { expect(serialized[:engagement_segment]).to eq('Pilier') }
        it 'does not change the unrelated badge field' do
          expect(serialized[:badge]).to eq(user.badge)
        end
      end
    end

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
