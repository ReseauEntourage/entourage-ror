require 'rails_helper'

describe SalesforceServices::UserTableInterface do
  let(:user) { create :user }

  describe '#last_engagement_date' do
    subject { described_class.new(instance: user).mapping.last_engagement_date }

    context 'without engagement' do
      it { expect(subject).to be_nil }
    end

    context 'with engagements' do
      before do
        create(:denorm_daily_engagements_with_type, user: user, date: Date.new(2026, 9, 1))
        create(:denorm_daily_engagements_with_type, user: user, date: Date.new(2026, 9, 15))
      end

      it { expect(subject).to eq('2026-09-15') }
    end
  end
end
