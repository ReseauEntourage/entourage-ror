require 'rails_helper'

RSpec.describe UserImpactStatsJob do
  let(:user) { create(:public_user) }

  it 'is enqueued on the denorm queue' do
    expect(described_class.get_sidekiq_options['queue']).to eq(:denorm)
  end

  context 'with a known counter' do
    subject { described_class.new.perform(user.id, UserStat::ACTION_CREATIONS) }

    before { create(:entourage, user: user) }

    it 'recomputes only that counter' do
      # jobs run inline in specs: the observer already created the row
      user.reload.user_stat.update_columns(action_creations_count: 0, neighborhood_messages_count: 4)

      subject

      expect(user.reload.user_stat).to have_attributes(action_creations_count: 1, neighborhood_messages_count: 4)
    end
  end

  context 'with a staff member' do
    let!(:team_member) { create(:user, targeting_profile: :team, partner: create(:partner, staff: true)) }
    let!(:admin) { create(:admin_user) }

    it 'does not recompute their conversation_members' do
      expect(UserStat).not_to receive(:refresh!)

      described_class.new.perform(team_member.id, UserStat::CONVERSATION_MEMBERS)
      described_class.new.perform(admin.id, UserStat::CONVERSATION_MEMBERS)
    end

    it 'still recomputes their other counters' do
      expect(UserStat).to receive(:refresh!).with(team_member.id, UserStat::ACTION_CREATIONS)
      expect(UserStat).to receive(:refresh!).with(admin.id, UserStat::NEIGHBORHOOD_MESSAGES)

      described_class.new.perform(team_member.id, UserStat::ACTION_CREATIONS)
      described_class.new.perform(admin.id, UserStat::NEIGHBORHOOD_MESSAGES)
    end
  end

  context 'when the user no longer exists' do
    subject { described_class.new.perform(0, UserStat::ACTION_CREATIONS) }

    it 'does nothing' do
      expect(UserStat).not_to receive(:refresh!)

      subject
    end
  end

  context 'with an unknown counter' do
    subject { described_class.new.perform(user.id, 'foo') }

    it { expect { subject }.to raise_error(ArgumentError) }
  end
end
