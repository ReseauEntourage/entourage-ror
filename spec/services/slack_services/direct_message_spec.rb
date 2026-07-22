require 'rails_helper'

describe SlackServices::DirectMessage do
  describe '#send!' do
    context 'when the user has no slack_id' do
      let(:user) { create(:pro_user, slack_id: nil) }

      it { expect(described_class.new(user: user, text: 'hello').send!).to eq(false) }
    end

    context 'when SLACK_BOT_TOKEN is not configured' do
      let(:user) { create(:pro_user, slack_id: 'U123') }

      before { allow(ENV).to receive(:[]).and_call_original }
      before { allow(ENV).to receive(:[]).with('SLACK_BOT_TOKEN').and_return(nil) }

      it { expect(described_class.new(user: user, text: 'hello').send!).to eq(false) }
    end

    context 'with a slack_id and a configured token' do
      let(:user) { create(:pro_user, slack_id: 'U123') }

      before { allow(ENV).to receive(:[]).and_call_original }
      before { allow(ENV).to receive(:[]).with('SLACK_BOT_TOKEN').and_return('xoxb-test') }

      it 'posts to the Slack Web API and returns true on success' do
        stub_request(:post, 'https://slack.com/api/chat.postMessage')
          .with(
            headers: { 'Authorization' => 'Bearer xoxb-test' },
            body: { channel: 'U123', text: 'hello' }.to_json
          )
          .to_return(status: 200, body: { ok: true }.to_json, headers: { 'Content-Type' => 'application/json' })

        expect(described_class.new(user: user, text: 'hello').send!).to eq(true)
      end

      it 'returns false when Slack responds with ok: false' do
        stub_request(:post, 'https://slack.com/api/chat.postMessage')
          .to_return(status: 200, body: { ok: false, error: 'channel_not_found' }.to_json, headers: { 'Content-Type' => 'application/json' })

        expect(described_class.new(user: user, text: 'hello').send!).to eq(false)
      end

      it 'returns false and reports to Sentry on network failure' do
        stub_request(:post, 'https://slack.com/api/chat.postMessage').to_raise(SocketError)

        expect(Sentry).to receive(:capture_exception)
        expect(described_class.new(user: user, text: 'hello').send!).to eq(false)
      end
    end
  end
end
