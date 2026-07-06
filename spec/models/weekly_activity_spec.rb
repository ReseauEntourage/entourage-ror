require 'rails_helper'

RSpec.describe WeeklyActivity, type: :model do
  subject { build(:weekly_activity) }

  it { should belong_to(:user) }
  it { should validate_presence_of(:user_id) }
  it { should validate_presence_of(:week_iso) }
  it { should validate_uniqueness_of(:week_iso).scoped_to(:user_id) }

  describe 'creation' do
    let(:user) { create(:public_user) }

    it 'saves a valid weekly activity' do
      activity = build(:weekly_activity, user: user, week_iso: '2026-W01')
      expect(activity.save).to be true
    end

    it 'prevents duplicate week_iso for same user' do
      create(:weekly_activity, user: user, week_iso: '2026-W01')
      duplicate = build(:weekly_activity, user: user, week_iso: '2026-W01')
      expect(duplicate).not_to be_valid
    end

    it 'allows same week_iso for different users' do
      other_user = create(:public_user)
      create(:weekly_activity, user: user, week_iso: '2026-W01')
      activity = build(:weekly_activity, user: other_user, week_iso: '2026-W01')
      expect(activity).to be_valid
    end
  end

  describe '.recent' do
    let(:user) { create(:public_user) }

    it 'orders by week_iso descending' do
      w1 = create(:weekly_activity, user: user, week_iso: '2026-W01')
      w3 = create(:weekly_activity, user: user, week_iso: '2026-W03')
      w2 = create(:weekly_activity, user: user, week_iso: '2026-W02')

      expect(WeeklyActivity.where(user: user).recent.to_a).to eq([w3, w2, w1])
    end
  end
end
