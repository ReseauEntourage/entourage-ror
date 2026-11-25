# What every read of the assistant guarantees, whatever the route (task 3.7 of EN-9878): refused
# without the API key of the assistant, refused for an anonymous, deleted, blocked or anonymized
# account, limited to the user of the token, and with no effect on their activity.
#
# The including group defines `call_route(key:, token:, params:)` (the request, key and token
# in headers only) and `user` (the account of the token). Routes with an `id` also pass
# `route_params` through `params`.
RSpec.shared_examples 'an assistant read' do
  let(:assistant_key) { 'assistant-secret-key' }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('ASSISTANT_API_KEY').and_return(assistant_key)
  end

  def error_code
    JSON.parse(response.body).dig('error', 'code')
  end

  def default_call(key: assistant_key, token: user.token, params: {})
    call_route(key: key, token: token, params: params)
  end

  describe 'access reserved to the assistant' do
    it 'refuses a missing API key' do
      default_call(key: nil)

      expect([response.status, error_code]).to eq([401, 'INVALID_API_KEY'])
    end

    it 'refuses a wrong API key, whatever the token' do
      default_call(key: 'another-key', token: 'unknown')

      expect([response.status, error_code]).to eq([401, 'INVALID_API_KEY'])
    end

    it 'refuses a missing token' do
      default_call(token: nil)

      expect([response.status, error_code]).to eq([401, 'INVALID_TOKEN'])
    end

    it 'refuses a token sent in the URL only' do
      default_call(token: nil, params: { token: user.token })

      expect([response.status, error_code]).to eq([401, 'INVALID_TOKEN'])
    end

    it 'refuses an anonymous account with a refusal of its own' do
      default_call(token: AnonymousUserService.token_from_uuid(SecureRandom.uuid, community: $server_community))

      expect([response.status, error_code]).to eq([403, 'ANONYMOUS_ACCOUNT'])
    end

    {
      'deleted' => { deleted: true },
      'blocked' => { validation_status: 'blocked' },
      'anonymized' => { validation_status: 'anonymized' }
    }.each do |label, attributes|
      it "refuses a #{label} account as an unknown token" do
        user.update_columns(attributes)

        default_call
        refused = [response.status, response.body]
        default_call(token: 'unknown')

        expect(refused).to eq([401, response.body])
      end
    end
  end

  describe 'no effect on the activity of the user' do
    it 'leaves the last sign in untouched and does not synchronize Salesforce nor track a session' do
      user.update_columns(last_sign_in_at: 1.month.ago)
      last_sign_in_at = user.reload.last_sign_in_at
      expect_any_instance_of(User).not_to receive(:sync_salesforce)
      expect(SessionHistory).not_to receive(:track)
      expect(RouteCompletionJob).not_to receive(:perform_async)

      default_call

      expect(response.status).to be < 500
      expect(user.reload.last_sign_in_at).to eq(last_sign_in_at)
    end

    it 'writes nothing about the user' do
      user
      expect { default_call }.not_to change { [User.maximum(:updated_at), SessionHistory.count, AssistantAction.count] }
    end
  end
end
