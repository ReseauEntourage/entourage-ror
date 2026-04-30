require 'rails_helper'

RSpec.describe UserServices::Engagement, type: :model do
  def refresh_engagement_levels
    ActiveRecord::Base.connection.execute(
      "REFRESH MATERIALIZED VIEW engagement_levels"
    )
  end

  let(:user) { create(:user) }

  describe '#engagement' do
    subject(:engagement) { user.engagement }

    context 'without engagement data' do
      before { refresh_engagement_levels }

      it 'returns 0 for all levels' do
        expect(engagement.level_1).to eq(0)
        expect(engagement.level_2).to eq(0)
        expect(engagement.level_3).to eq(0)
      end

      it 'returns score 0' do
        expect(engagement.score).to eq(0)
      end

      it 'returns SILENT badge' do
        expect(engagement.badge).to eq(UserServices::Engagement::BADGE_LABELS["SILENT"])
      end

      it 'is not engaged' do
        expect(engagement.engaged?).to be false
      end
    end

    context 'with engagement data' do
      before do
        create(:denorm_daily_engagements_with_type, user: user, engagement_type: 'reaction', date: 1.day.ago.to_date)
        create(:denorm_daily_engagements_with_type, user: user, engagement_type: 'reaction', date: 2.day.ago.to_date)

        create(:denorm_daily_engagements_with_type, user: user, engagement_type: 'post_message', date: 2.day.ago.to_date)

        refresh_engagement_levels
      end

      it 'returns correct levels' do
        expect(engagement.level_1).to eq(2)
        expect(engagement.level_2).to eq(1)
        expect(engagement.level_3).to eq(0)
      end

      it 'computes score' do
        expect(engagement.score).to eq(3)
      end

      it 'is engaged' do
        expect(engagement.engaged?).to be true
      end
    end

    describe 'badge mapping' do
      before do
        level_3_count.times do |time|
          create(:denorm_daily_engagements_with_type, user: user, engagement_type: 'create_group', date: time.day.ago.to_date)
        end

        level_2_count.times do |time|
          create(:denorm_daily_engagements_with_type, user: user, engagement_type: 'post_message', date: time.day.ago.to_date)
        end

        level_1_count.times do |time|
          create(:denorm_daily_engagements_with_type, user: user, engagement_type: 'reaction', date: time.day.ago.to_date)
        end

        refresh_engagement_levels
      end

      context 'SUPER_ENGAGE' do
        let(:level_3_count) { 2 }
        let(:level_2_count) { 0 }
        let(:level_1_count) { 0 }

        it do
          expect(user.badge).to eq(UserServices::Engagement::BADGE_LABELS["SUPER_ENGAGE"])
        end
      end

      context 'ENGAGE' do
        let(:level_3_count) { 0 }
        let(:level_2_count) { 2 }
        let(:level_1_count) { 0 }

        it do
          expect(user.badge).to eq(UserServices::Engagement::BADGE_LABELS["ENGAGE"])
        end
      end

      context 'OBSERVE' do
        let(:level_3_count) { 0 }
        let(:level_2_count) { 0 }
        let(:level_1_count) { 3 }

        it do
          expect(user.badge).to eq(UserServices::Engagement::BADGE_LABELS["OBSERVE"])
        end
      end

      context 'PASSIVE' do
        let(:level_3_count) { 0 }
        let(:level_2_count) { 0 }
        let(:level_1_count) { 1 }

        it do
          expect(user.badge).to eq(UserServices::Engagement::BADGE_LABELS["PASSIVE"])
        end
      end
    end
  end

  describe '.engaged' do
    let!(:engaged_user) do
      user = create(:user)
      create(
        :denorm_daily_engagements_with_type,
        user: user,
        engagement_type: 'reaction'
      )
      user
    end

    let!(:not_engaged_user) { create(:user) }

    before { refresh_engagement_levels }

    it 'returns engaged users only' do
      expect(User.engaged).to include(engaged_user)
      expect(User.engaged).not_to include(not_engaged_user)
    end
  end

  describe '.not_engaged' do
    let!(:silent_user) { create(:user) }

    let!(:engaged_user) do
      user = create(:user)
      create(:denorm_daily_engagements_with_type, user: user, engagement_type: 'reaction')
      user
    end

    before { refresh_engagement_levels }

    it 'returns non engaged users' do
      expect(User.not_engaged).to include(silent_user)
      expect(User.not_engaged).not_to include(engaged_user)
    end
  end
end
