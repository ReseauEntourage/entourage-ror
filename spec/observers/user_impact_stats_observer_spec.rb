require 'rails_helper'

RSpec.describe UserImpactStatsObserver do
  let(:user) { create(:public_user) }

  describe 'action creation' do
    it 'enqueues the action_creations recompute of its creator' do
      expect(UserImpactStatsJob).to receive(:perform_async).with(user.id, UserStat::ACTION_CREATIONS)

      create(:entourage, user: user)
    end

    it 'enqueues it for contributions and solicitations too' do
      expect(UserImpactStatsJob).to receive(:perform_async).with(user.id, UserStat::ACTION_CREATIONS).twice

      create(:contribution, user: user)
      create(:solicitation, user: user)
    end
  end

  describe 'action update' do
    let!(:action) { create(:entourage, user: user, status: :open) }

    it 'enqueues the recompute on a status change' do
      expect(UserImpactStatsJob).to receive(:perform_async).with(user.id, UserStat::ACTION_CREATIONS)

      action.update!(status: :suspended)
    end

    it 'does not enqueue on another change' do
      expect(UserImpactStatsJob).not_to receive(:perform_async)

      action.update!(title: 'another title')
    end
  end

  describe 'other entourages' do
    it 'does not enqueue for events, conversations or neighborhoods' do
      expect(UserImpactStatsJob).not_to receive(:perform_async)

      create(:outing, user: user)
      create(:conversation, user: user)
      create(:neighborhood, user: user)
    end
  end
end
