require 'rails_helper'

describe Api::V1::Assistant::TeamAlertsController, type: :controller do
  let(:user) { create :public_user, token: 'user-secret-token', first_name: 'Camille', last_name: 'Dupont' }
  let(:message) { "Je ne me sens pas en sécurité, rappelez-moi s'il vous plaît." }

  def call_action(key:, api_key:, token:, params:)
    request.headers['X-API-KEY'] = api_key if api_key
    request.headers['Authorization'] = "Bearer #{token}" if token
    request.headers['Idempotency-Key'] = key if key
    post :raise_alert, params: params, as: :json
  end

  let(:valid_params) { { audience: 'team', message: message } }
  let(:other_params) { valid_params.merge(message: 'Autre texte') }
  let(:action_type) { 'team.alert' }

  # The alert has no object of its own: it leaves no subject.
  describe 'the common guarantees of the actions' do
    it_behaves_like 'an assistant action' do
      let(:subject_class) { NilClass }
    end
  end

  it 'is routed to POST /api/v1/assistant/alerts' do
    expect(post: '/api/v1/assistant/alerts').to route_to('api/v1/assistant/team_alerts#raise_alert')
  end

  context 'when it runs' do
    let(:animator) { create :public_user, first_name: 'Nadia', slack_id: 'U0NADIA' }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('ASSISTANT_API_KEY').and_return('assistant-secret-key')
      allow(ENV).to receive(:[]).with('ASSISTANT_ACTIONS_ENABLED').and_return('true')
    end

    def alert(params = valid_params, key: SecureRandom.uuid)
      @controller = described_class.new
      call_action(key: key, api_key: 'assistant-secret-key', token: user.token, params: params)
    end

    def body
      JSON.parse(response.body)
    end

    # slack-notifier posts a form: payload=<json>
    def slack_payload(request)
      JSON.parse(CGI.parse(request.body)['payload'].first)
    end

    def slack_requests
      a_request(:post, 'https://url.to.slack.com').with { |request| slack_payload(request)['attachments'].first['text'].include?('Camille Dupont') }
    end

    it 'passes the exact approved message to the team, with the person, without a named contact' do
      create :moderation_area, departement: '*', animator: animator

      alert

      expect(response.status).to eq(201)
      expect(body).to eq('kind' => 'safety_signal', 'status' => 'sent', 'withContact' => false)
      expect(a_request(:post, 'https://url.to.slack.com').with { |request|
        payload = slack_payload(request)
        payload['attachments'].map { |a| a['text'] }.include?("Message : #{message}") &&
          payload['attachments'].first['text'].start_with?('Personne : Camille Dupont') &&
          !payload['text'].include?('<@')
      }).to have_been_made.once
    end

    it 'names the dedicated contact on Slack when the referent is warned and there is one' do
      create :moderation_area, departement: '*', animator: animator

      alert(valid_params.merge(audience: 'referent'))

      expect(body).to eq('kind' => 'handover', 'status' => 'sent', 'withContact' => true)
      expect(a_request(:post, 'https://url.to.slack.com').with { |request| slack_payload(request)['text'].start_with?('<@U0NADIA>') }).to have_been_made.once
    end

    it 'warns the team alone when the referent is asked and the person has no dedicated contact' do
      alert(valid_params.merge(audience: 'referent'))

      expect(body).to eq('kind' => 'handover', 'status' => 'sent', 'withContact' => false)
      expect(a_request(:post, 'https://url.to.slack.com').with { |request| slack_payload(request)['text'].start_with?('Team modération') }).to have_been_made.once
    end

    it 'keeps the kind sent by the assistant: a negative feedback after a meeting, for the team or the referent' do
      alert(valid_params.merge(kind: 'negative_feedback'))
      expect(body['kind']).to eq('negative_feedback')

      alert(valid_params.merge(audience: 'referent', kind: 'safety_signal'))
      expect(body['kind']).to eq('safety_signal')
    end

    it 'does not break the action when Slack fails: it is reported and the result says it was not delivered' do
      stub_request(:post, 'https://url.to.slack.com').to_timeout
      allow(Sentry).to receive(:capture_message)

      alert

      expect(response.status).to eq(201)
      expect(body).to include('status' => 'not_delivered')
      expect(Sentry).to have_received(:capture_message).once
      expect(AssistantAction.last).to be_succeeded
    end

    it 'passes the message once when the request is replayed' do
      key = SecureRandom.uuid

      2.times { alert(key: key) }

      expect(slack_requests).to have_been_made.once
    end

    it 'refuses an unknown audience, an unknown kind and an empty message, and passes nothing' do
      alert(valid_params.merge(audience: 'everyone'))
      expect([response.status, body.dig('error', 'code')]).to eq([400, 'INVALID_PARAMS'])

      alert(valid_params.merge(kind: 'spam'))
      expect([response.status, body.dig('error', 'code')]).to eq([400, 'INVALID_PARAMS'])

      alert(valid_params.merge(message: ' '))
      expect([response.status, body.dig('error', 'code')]).to eq([400, 'INVALID_PARAMS'])
      expect(slack_requests).not_to have_been_made
    end

    it 'never writes the message in the table of actions' do
      alert

      expect(AssistantAction.last.attributes.values.join).not_to include('sécurité')
    end
  end
end
