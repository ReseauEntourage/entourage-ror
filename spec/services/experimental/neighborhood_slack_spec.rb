require 'rails_helper'

describe Experimental::NeighborhoodSlack do
  # the user lives in Paris (75) and creates a group elsewhere
  let(:user) { create :public_user, :paris }

  let(:slack_app_webhooks) { { prefix: 'https://hooks.slack.com/', default: 'DEFAULT', '75': 'C75', '33': 'C33', '10': 'C10' }.to_json }
  let(:slack_notifier) { instance_double(Slack::Notifier, ping: nil) }

  before do
    neighborhood

    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('SLACK_APP_WEBHOOKS').and_return(slack_app_webhooks)
    allow(Slack::Notifier).to receive(:new).and_return(slack_notifier)

    Experimental::NeighborhoodSlack.notify(neighborhood.id)
  end

  context 'when the group is in France' do
    let(:neighborhood) { create :neighborhood, user: user, country: 'FR', postal_code: '33000' }

    it 'posts in the channel of the group departement' do
      expect(Slack::Notifier).to have_received(:new).with('https://hooks.slack.com/C33')
    end
  end

  context 'when the group is outside of France' do
    # Brussels postal code starts like Aube (10)
    let(:neighborhood) { create :neighborhood, user: user, country: 'BE', postal_code: '1000' }

    it 'posts in the default channel' do
      expect(Slack::Notifier).to have_received(:new).with('https://hooks.slack.com/DEFAULT')
    end
  end
end
