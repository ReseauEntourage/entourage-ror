require 'rails_helper'

describe NextStepServices::EngagementLevel do
  let(:user) { FactoryBot.create(:public_user) }

  subject { described_class.new(user: user).call }

  describe 'dormant detection' do
    it 'returns :dormant when user has not signed in for 30+ days' do
      user.update_column(:last_sign_in_at, 31.days.ago)
      expect(subject).to eq(:dormant)
    end

    it 'does not return :dormant when user signed in recently' do
      user.update_column(:last_sign_in_at, 1.day.ago)
      expect(subject).not_to eq(:dormant)
    end
  end

  describe 'level 0' do
    before { user.update_column(:last_sign_in_at, 1.day.ago) }

    it 'returns 0 when user has no accepted join requests' do
      expect(subject).to eq(0)
    end
  end

  describe 'level 1' do
    before { user.update_column(:last_sign_in_at, 1.day.ago) }

    it 'returns 1 when user has 1 accepted join request' do
      FactoryBot.create(:join_request, user: user, status: 'accepted')
      expect(subject).to eq(1)
    end

    it 'returns 1 when user has 2 accepted join requests' do
      FactoryBot.create_list(:join_request, 2, user: user, status: 'accepted')
      expect(subject).to eq(1)
    end
  end

  describe 'level 2' do
    before { user.update_column(:last_sign_in_at, 1.day.ago) }

    it 'returns 2 when user has 3 or more accepted join requests without recurring activity' do
      FactoryBot.create_list(:join_request, 3, user: user, status: 'accepted')
      expect(subject).to eq(2)
    end
  end

  describe 'level 3' do
    before { user.update_column(:last_sign_in_at, 1.day.ago) }

    it 'returns 3 when user has 8+ accepted join requests spanning 2+ months in the last 60 days' do
      # Create join requests spread across 2 different months within last 60 days
      FactoryBot.create_list(:join_request, 4, user: user, status: 'accepted',
        created_at: 50.days.ago)
      FactoryBot.create_list(:join_request, 4, user: user, status: 'accepted',
        created_at: 10.days.ago)
      expect(subject).to eq(3)
    end

    it 'returns 2 when user has 8+ join requests but all in same month' do
      FactoryBot.create_list(:join_request, 8, user: user, status: 'accepted',
        created_at: 5.days.ago)
      expect(subject).to eq(2)
    end
  end
end
