require 'rails_helper'

RSpec.describe 'engagement_levels materialized view', type: :model do
  def refresh_engagement_levels
    ActiveRecord::Base.connection.execute(
      "REFRESH MATERIALIZED VIEW engagement_levels"
    )
  end

  let(:user) { create(:user) }

  describe 'aggregation' do
    before do
      # reactions
      create(:denorm_daily_engagements_with_type, user: user, engagement_type: 'reaction', date: Date.today)
      create(:denorm_daily_engagements_with_type, user: user, engagement_type: 'reaction', date: 1.day.ago.to_date)
      create(:denorm_daily_engagements_with_type, user: user, engagement_type: 'reaction', date: 2.day.ago.to_date)

      # post_message
      create(:denorm_daily_engagements_with_type, user: user, engagement_type: 'post_message', date: Date.today)
      create(:denorm_daily_engagements_with_type, user: user, engagement_type: 'post_message', date: 1.day.ago.to_date)

      # create_group
      create(:denorm_daily_engagements_with_type, user: user, engagement_type: 'create_group', date: Date.today)

      refresh_engagement_levels
    end

    let(:row) { EngagementLevel.find_by(user_id: user.id) }

    it 'computes level_1_count correctly' do
      expect(row.level_1_count).to eq(3)
    end

    it 'computes level_2_count correctly' do
      expect(row.level_2_count).to eq(2)
    end

    it 'computes level_3_count correctly' do
      expect(row.level_3_count).to eq(1)
    end
  end

  describe 'badge computation (SQL CASE)' do
    let(:row) { EngagementLevel.find_by(user_id: user.id) }

    context 'SUPER_ENGAGE' do
      before do
        create(:denorm_daily_engagements_with_type, user: user, engagement_type: 'create_group', date: Date.today)
        create(:denorm_daily_engagements_with_type, user: user, engagement_type: 'create_group', date: 1.day.ago.to_date)

        refresh_engagement_levels
      end

      it { expect(row.badge).to eq('SUPER_ENGAGE') }
    end

    context 'ENGAGE' do
      before do
        create(:denorm_daily_engagements_with_type, user: user, engagement_type: 'post_message', date: Date.today)
        create(:denorm_daily_engagements_with_type, user: user, engagement_type: 'post_message', date: 1.day.ago.to_date)

        refresh_engagement_levels
      end

      it { expect(row.badge).to eq('ENGAGE') }
    end

    context 'OBSERVE' do
      before do
        create(:denorm_daily_engagements_with_type, user: user, engagement_type: 'reaction', date: Date.today)
        create(:denorm_daily_engagements_with_type, user: user, engagement_type: 'reaction', date: 1.day.ago.to_date)
        create(:denorm_daily_engagements_with_type, user: user, engagement_type: 'reaction', date: 2.day.ago.to_date)

        refresh_engagement_levels
      end

      it { expect(row.badge).to eq('OBSERVE') }
    end

    context 'PASSIVE' do
      before do
        create(:denorm_daily_engagements_with_type, user: user, engagement_type: 'reaction')

        refresh_engagement_levels
      end

      it { expect(row.badge).to eq('PASSIVE') }
    end

    context 'SILENT (no data)' do
      before do
        refresh_engagement_levels
      end

      it 'does not create a row' do
        expect(row).to be_nil
      end
    end
  end
end
