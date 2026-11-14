require 'rails_helper'

RSpec.describe NextSteps::Alert do
  before { allow(Sentry).to receive(:capture_message) }

  context 'when a papotage is scheduled and the segments are fresh' do
    before do
      create(:outing, online: true, title: 'Papotage solidaire', metadata: { starts_at: 3.days.from_now })
      create(:user_segment, segment_computed_at: 1.day.ago)
    end

    it 'sends nothing' do
      expect(described_class.call).to be_empty
      expect(Sentry).not_to have_received(:capture_message)
    end
  end

  it 'warns when no papotage is scheduled within 7 days' do
    create(:outing, online: true, title: 'Papotage solidaire', metadata: { starts_at: 10.days.from_now })
    create(:user_segment, segment_computed_at: 1.day.ago)

    expect(described_class.call).to eq(['no papotage is scheduled within 7 days'])
    expect(Sentry).to have_received(:capture_message).with('next_steps: no papotage is scheduled within 7 days', level: :warning)
  end

  it 'warns when the segments are more than 2 days old' do
    create(:outing, online: true, title: 'Papotage solidaire', metadata: { starts_at: 3.days.from_now })
    create(:user_segment, segment_computed_at: 3.days.ago)

    expect(described_class.call.first).to start_with('engagement segments were last computed at')
    expect(Sentry).to have_received(:capture_message).once
  end
end
