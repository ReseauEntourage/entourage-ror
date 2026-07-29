require 'rails_helper'

RSpec.describe UserStatsJob do
  let(:user) { create(:public_user) }

  subject { described_class.new.perform(user.id) }

  it 'recomputes the stats counters for the user' do
    expect_any_instance_of(User).to receive(:stats_has_changed!)

    subject
  end

  context 'when the user no longer exists' do
    subject { described_class.new.perform(0) }

    it 'does nothing' do
      expect_any_instance_of(User).not_to receive(:stats_has_changed!)

      subject
    end
  end
end
