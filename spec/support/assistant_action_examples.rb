# What every action of the assistant guarantees, whatever the route (EN-9878): refused without the
# API key or while the switch is off, refused without an idempotency key, run once per key, recorded
# in assistant_actions with its subject, and without any effect on the connection of the user.
#
# The including group defines `user`, `call_action(key:, api_key:, token:, params:)` (the request,
# keys and token in headers only), `valid_params` (a valid body), `other_params` (another valid body, for a key reused for another
# request), `action_type` and `subject_class`.
RSpec.shared_examples 'an assistant action' do
  let(:assistant_key) { 'assistant-secret-key' }
  let(:actions_enabled) { 'true' }
  let(:idempotency_key) { SecureRandom.uuid }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('ASSISTANT_API_KEY').and_return(assistant_key)
    allow(ENV).to receive(:[]).with('ASSISTANT_ACTIONS_ENABLED').and_return(actions_enabled)
  end

  def perform(key: idempotency_key, api_key: assistant_key, token: user.token, params: valid_params)
    @controller = described_class.new # a controller keeps what it memoized from a previous request
    call_action(key: key, api_key: api_key, token: token, params: params)
  end

  def body
    JSON.parse(response.body)
  end

  def error_code
    body.dig('error', 'code')
  end

  describe 'access reserved to the assistant' do
    it 'refuses a missing or wrong API key, and does nothing' do
      expect { perform(api_key: nil) }.not_to change { AssistantAction.count }
      expect([response.status, error_code]).to eq([401, 'INVALID_API_KEY'])

      perform(api_key: 'other')
      expect([response.status, error_code]).to eq([401, 'INVALID_API_KEY'])
    end

    it 'refuses a missing token' do
      perform(token: nil)

      expect([response.status, error_code]).to eq([401, 'INVALID_TOKEN'])
    end

    it 'refuses an anonymous account' do
      perform(token: AnonymousUserService.token_from_uuid(SecureRandom.uuid, community: $server_community))

      expect([response.status, error_code]).to eq([403, 'ANONYMOUS_ACCOUNT'])
    end

    context 'when the actions are switched off' do
      let(:actions_enabled) { nil }

      it 'answers 503 ACTIONS_DISABLED and does nothing' do
        expect { perform }.not_to change { AssistantAction.count }

        expect([response.status, error_code]).to eq([503, 'ACTIONS_DISABLED'])
      end
    end
  end

  describe 'idempotency' do
    it 'refuses an action without key, and does nothing' do
      expect { perform(key: nil) }.not_to change { AssistantAction.count }

      expect([response.status, error_code]).to eq([400, 'IDEMPOTENCY_KEY_REQUIRED'])
    end

    it 'records the action with its type, its key and its subject' do
      perform

      expect(response.status).to be_between(200, 201)
      row = AssistantAction.find_by!(user_id: user.id, idempotency_key: idempotency_key)
      expect(row).to have_attributes(action_type: action_type, status: 'succeeded')
      expect(row.subject).to be_a(subject_class)
    end

    it 'answers the same thing to a replayed request, and records it once' do
      perform
      first = [response.status, body]

      expect { perform }.not_to change { AssistantAction.count }
      expect([response.status, body]).to eq(first)
      expect(response.headers['Idempotent-Replayed']).to eq('true')
    end

    it 'refuses the same key for another request' do
      perform
      perform(params: other_params)

      expect([response.status, error_code]).to eq([422, 'IDEMPOTENCY_KEY_REUSED'])
    end

    it 'never keeps the text of the request in the table' do
      perform

      expect(AssistantAction.where(user_id: user.id).pluck(:result, :request_digest).to_json).not_to include('Bonjour')
    end
  end

  describe 'no effect on the connection of the user' do
    it 'leaves the last sign in untouched and does not synchronize Salesforce nor track a session' do
      user.update_columns(last_sign_in_at: 1.month.ago)
      last_sign_in_at = user.reload.last_sign_in_at
      expect(SessionHistory).not_to receive(:track)
      expect(RouteCompletionJob).not_to receive(:perform_async)

      perform

      expect(user.reload.last_sign_in_at).to eq(last_sign_in_at)
    end
  end
end
