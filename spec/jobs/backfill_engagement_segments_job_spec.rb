require 'rails_helper'

RSpec.describe BackfillEngagementSegmentsJob do
  let(:user) { create(:user, deleted: false, targeting_profile: nil) }

  before do
    # Lifetime session count - unaffected by which day gets replayed.
    create(:session_history, user: user, date: 40.days.ago.to_date)
    create(:session_history, user: user, date: 39.days.ago.to_date)

    # Logged in regularly enough to stay eligible (via login_histories) for
    # every day in the reconstructed range.
    (0..40).step(5).each do |n|
      create(:login_history, user: user, connected_at: n.days.ago)
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
    LoginHistory.delete_all
    create(:denorm_daily_engagements_with_type, user: user, engagement_type: 'create_group', date: 5.days.ago.to_date)
    create(:login_history, user: user, connected_at: 5.days.ago)

    described_class.perform_now(months: 6)

    expect(UserSegmentHistory.count).to eq(0)
  end
end
