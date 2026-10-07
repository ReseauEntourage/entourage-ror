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
    it { expect(serialized).to have_key(:past_outing_participations_count) }
    it { expect(serialized).to have_key(:action_creations_count) }
    it { expect(serialized).to have_key(:neighborhood_messages_count) }
    it { expect(serialized).to have_key(:conversation_members_count) }
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

      context 'one cancelled past outing, no action' do
        let(:outing) { create(:outing, status: :cancelled, metadata: { starts_at: 2.days.ago, ends_at: 1.day.ago }) }
        let!(:join_request) { create(:join_request, joinable: outing, user: user, status: :accepted) }

        it { expect(serialized[:meetings_count]).to eq(0) }
      end

      context 'two past outings and one action with outcome Oui' do
        let(:outings) { create_list(:outing, 2, metadata: { starts_at: 2.days.ago, ends_at: 1.day.ago }) }
        let!(:join_requests) { outings.map { |outing| create(:join_request, joinable: outing, user: user, status: :accepted) } }
        let!(:entourage) { create(:entourage, :outcome_oui, user: user, status: :closed) }

        it { expect(serialized[:past_outing_participations_count]).to eq(2) }
        it { expect(serialized[:meetings_count]).to eq(3) }
      end
    end

    describe 'past_outing_participations_count' do
      let(:status) { :open }
      let(:metadata) { { starts_at: 2.days.ago, ends_at: 1.day.ago } }
      let(:join_request_status) { :accepted }
      let(:outing) { create(:outing, status: status, metadata: metadata) }

      before { create(:join_request, joinable: outing, user: user, status: join_request_status) }

      subject { serialized[:past_outing_participations_count] }

      context 'past outing attended' do
        it { expect(subject).to eq(1) }
      end

      context 'future outing' do
        let(:metadata) { { starts_at: 1.day.from_now, ends_at: 2.days.from_now } }

        it { expect(subject).to eq(0) }
      end

      [:cancelled, :blacklisted, :suspended].each do |uncounted_status|
        context "#{uncounted_status} past outing" do
          let(:status) { uncounted_status }

          it { expect(subject).to eq(0) }
        end
      end

      context 'closed past outing' do
        let(:status) { :closed }

        it { expect(subject).to eq(1) }
      end

      context 'pending membership' do
        let(:join_request_status) { :pending }

        it { expect(subject).to eq(0) }
      end
    end

    describe 'past_outing_participations_count of an organizer' do
      let(:outing) { create(:outing, user: user, metadata: { starts_at: 2.days.ago, ends_at: 1.day.ago }) }

      before { create(:join_request, joinable: outing, user: user, status: :accepted, role: :organizer) }

      it { expect(serialized[:past_outing_participations_count]).to eq(1) }
    end

    describe 'denormalized impact counts' do
      context 'without user_stats row' do
        it { expect(serialized[:action_creations_count]).to eq(0) }
        it { expect(serialized[:neighborhood_messages_count]).to eq(0) }
        it { expect(serialized[:conversation_members_count]).to eq(0) }
      end

      context 'with a user_stats row' do
        before do
          UserStat.create!(user: user, action_creations_count: 2, neighborhood_messages_count: 5, conversation_members_count: 3)
        end

        it { expect(serialized[:action_creations_count]).to eq(2) }
        it { expect(serialized[:neighborhood_messages_count]).to eq(5) }
        it { expect(serialized[:conversation_members_count]).to eq(3) }
      end
    end
  end
end
