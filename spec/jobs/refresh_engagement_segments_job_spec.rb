require 'rails_helper'

RSpec.describe RefreshEngagementSegmentsJob do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user, last_sign_in_at: 1.day.ago, targeting_profile: nil, deleted: false) }

  def engagement(user, type, date: Date.current)
    create(:denorm_daily_engagements_with_type, user: user, engagement_type: type, date: date)
  end

  describe 'segment_computed_at freshness' do
    before { engagement(user, 'reaction') } # Curieux, stable across runs

    it 'advances on every run, even when the segment is unchanged' do
      described_class.perform_now
      user_segment = UserSegment.find_by(user_id: user.id)
      expect(user_segment.engagement_segment).to eq('Curieux')

      user_segment.update_column(:segment_computed_at, 1.day.ago)

      described_class.perform_now
      user_segment.reload

      expect(user_segment.engagement_segment).to eq('Curieux')
      expect(user_segment.segment_computed_at).to be > 1.hour.ago
    end
  end

  describe 'transition history' do
    it 'does not add a history row when the segment is unchanged across runs' do
      engagement(user, 'reaction')

      described_class.perform_now
      described_class.perform_now

      expect(UserSegmentHistory.where(user_id: user.id).count).to eq(1)
    end

    it 'adds exactly one new history row when the segment changes on a later day, closing the previous one' do
      day1 = Date.current

      engagement(user, 'reaction') # Curieux
      described_class.perform_now

      first_entry = UserSegmentHistory.where(user_id: user.id).sole
      expect(first_entry.engagement_segment).to eq('Curieux')
      expect(first_entry.valid_to).to be_nil

      travel_to(1.day.from_now) do
        engagement(user, 'create_group')
        engagement(user, 'create_action') # now Pilier

        described_class.perform_now
      end

      entries = UserSegmentHistory.where(user_id: user.id).order(:valid_from)
      expect(entries.count).to eq(2)
      expect(entries.first.valid_from).to eq(day1)
      expect(entries.first.valid_to).to eq(day1 + 1)
      expect(entries.last.engagement_segment).to eq('Pilier')
      expect(entries.last.valid_to).to be_nil
    end
  end

  describe 'eligibility loss' do
    it 'resets a previously-classified user to unclassified and records the transition' do
      day1 = Date.current

      engagement(user, 'reaction') # Curieux
      described_class.perform_now
      expect(UserSegment.find_by(user_id: user.id).engagement_segment).to eq('Curieux')

      travel_to(1.day.from_now) do
        user.update_column(:last_sign_in_at, 40.days.ago)

        described_class.perform_now
      end

      user_segment = UserSegment.find_by(user_id: user.id)
      expect(user_segment.engagement_segment).to be_nil
      expect(user_segment.engagement_sub_segment).to be_nil

      entries = UserSegmentHistory.where(user_id: user.id).order(:valid_from)
      expect(entries.count).to eq(2)
      expect(entries.first.engagement_segment).to eq('Curieux')
      expect(entries.first.valid_from).to eq(day1)
      expect(entries.first.valid_to).to eq(day1 + 1)
      expect(entries.last.engagement_segment).to be_nil
      expect(entries.last.valid_to).to be_nil
    end
  end
end
