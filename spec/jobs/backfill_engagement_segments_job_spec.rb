require 'rails_helper'

RSpec.describe BackfillEngagementSegmentsJob do
  let(:user) { create(:user, deleted: false, targeting_profile: nil) }

  before do
    # Session activity: feeds both the lifetime session count and (in
    # backfill mode) the eligibility check, spaced to cover every day in
    # the reconstructed range below.
    [40, 35, 30, 25, 20, 15, 10, 5, 0].each do |n|
      create(:session_history, user: user, date: n.days.ago.to_date)
    end

    # A burst of strong engagement 40 days ago - only inside the trailing
    # 30-day window on the earliest day that can be reliably reconstructed.
    create(:denorm_daily_engagements_with_type, user: user, engagement_type: 'create_group', date: 40.days.ago.to_date)
    create(:denorm_daily_engagements_with_type, user: user, engagement_type: 'create_action', date: 40.days.ago.to_date)
  end

  it 'clamps the reconstructed range to what the source data actually supports' do
    described_class.perform_now(months: 6)

    first_entry = UserSegmentHistory.where(user_id: user.id).order(:valid_from).first
    expect(first_entry.valid_from).to eq(10.days.ago.to_date)
  end

  it 'reconstructs the transition as the burst ages out of the 30-day window' do
    described_class.perform_now(months: 6)

    entries = UserSegmentHistory.where(user_id: user.id).order(:valid_from).to_a
    expect(entries.first.engagement_segment).to eq('Pilier')
    expect(entries.first.valid_from).to eq(10.days.ago.to_date)
    expect(entries.second.engagement_segment).to eq('Silencieux')
    expect(entries.second.valid_from).to eq(9.days.ago.to_date)
    expect(entries.last.valid_to).to be_nil
  end

  it 'leaves user_segments reflecting the most recently reconstructed day, not today' do
    described_class.perform_now(months: 6)

    user_segment = UserSegment.find_by(user_id: user.id)
    expect(user_segment.engagement_segment).to eq('Silencieux')
  end

  it 'does nothing when there is not enough historical depth for a single reliable day' do
    DenormDailyEngagementsWithType.delete_all
    SessionHistory.delete_all
    create(:denorm_daily_engagements_with_type, user: user, engagement_type: 'create_group', date: 5.days.ago.to_date)
    create(:session_history, user: user, date: 5.days.ago.to_date)

    described_class.perform_now(months: 6)

    expect(UserSegmentHistory.count).to eq(0)
  end

  it 'refuses to run against a stale eligibility source' do
    SessionHistory.delete_all
    create(:session_history, user: user, date: 40.days.ago.to_date)

    expect { described_class.perform_now(months: 6) }.to raise_error(/session_histories looks stale/)
  end

  context 'when segments were already computed (nightly job or previous backfill)' do
    def history_of(user)
      UserSegmentHistory.where(user_id: user.id).order(:valid_from).pluck(:engagement_segment, :valid_from, :valid_to)
    end

    before do
      create(:user_segment, user: user, engagement_segment: 'Curieux')
      create(:user_segment_history, user: user, engagement_segment: 'Curieux', valid_from: Date.current)
    end

    it 'refuses to replay over them by default, leaving them untouched' do
      expect { described_class.perform_now(months: 6) }.to raise_error(/Pass reset: true/)

      expect(history_of(user)).to eq([['Curieux', Date.current, nil]])
      expect(UserSegment.find_by(user_id: user.id).engagement_segment).to eq('Curieux')
    end

    it 'truncates and rebuilds both tables with reset: true' do
      described_class.perform_now(months: 6, reset: true)

      expect(history_of(user)).to eq([
        ['Pilier', 10.days.ago.to_date, 9.days.ago.to_date],
        ['Silencieux', 9.days.ago.to_date, nil]
      ])
      expect(UserSegment.find_by(user_id: user.id).engagement_segment).to eq('Silencieux')
    end

    it 'can be run again with reset: true (e.g. after a crash midway)' do
      described_class.perform_now(months: 6, reset: true)

      expect { described_class.perform_now(months: 6, reset: true) }.not_to change { history_of(user) }
    end

    it 'does not wipe anything when the backfill then refuses to run' do
      SessionHistory.delete_all
      create(:session_history, user: user, date: 40.days.ago.to_date)

      expect { described_class.perform_now(months: 6, reset: true) }.to raise_error(/session_histories looks stale/)
      expect(history_of(user)).to eq([['Curieux', Date.current, nil]])
    end

    it 'does not wipe anything when there is not enough depth to replay a single day' do
      DenormDailyEngagementsWithType.delete_all
      create(:denorm_daily_engagements_with_type, user: user, engagement_type: 'create_group', date: 5.days.ago.to_date)

      described_class.perform_now(months: 6, reset: true)

      expect(history_of(user)).to eq([['Curieux', Date.current, nil]])
    end
  end
end
