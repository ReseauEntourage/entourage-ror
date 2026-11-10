require 'rails_helper'

describe Api::V1::Assistant::IdentityController, type: :controller do
  let(:assistant_key) { 'assistant-secret-key' }
  let(:user) { create :public_user, first_name: 'Camille', token: 'user-secret-token', goal: 'offer_help' }
  let(:body) { JSON.parse(response.body) }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('ASSISTANT_API_KEY').and_return(assistant_key)
  end

  # Calls the route the way the assistant does: key and token in headers only.
  def read_identity(token: user.token, key: assistant_key, params: {})
    request.headers['X-API-KEY'] = key if key
    request.headers['Authorization'] = "Bearer #{token}" if token
    get :read, params: params
  end

  def expect_error(status, code)
    expect(response.status).to eq status
    expect(body).to eq('error' => { 'code' => code, 'message' => body.dig('error', 'message') })
    expect(body.dig('error', 'message')).to be_present
  end

  it 'is routed to GET /api/v1/assistant/identity' do
    expect(get: '/api/v1/assistant/identity').to route_to('api/v1/assistant/identity#read')
    expect(post: '/api/v1/assistant/identity').not_to be_routable
  end

  describe 'API key of the assistant' do
    it 'refuses a missing key, before reading any account' do
      expect(User).not_to receive(:eager_load)

      read_identity(key: nil)

      expect_error 401, 'INVALID_API_KEY'
    end

    it 'refuses a wrong key, before reading any account' do
      expect(User).not_to receive(:eager_load)

      read_identity(key: 'another-key')

      expect_error 401, 'INVALID_API_KEY'
    end

    it 'refuses a key that is only a prefix of the right one' do
      read_identity(key: assistant_key[0, 5])

      expect_error 401, 'INVALID_API_KEY'
    end

    context 'when the key is not configured' do
      let(:assistant_key) { nil }

      it 'refuses every request, even one that sends an empty key' do
        expect(User).not_to receive(:eager_load)

        read_identity(key: '')

        expect_error 401, 'INVALID_API_KEY'
      end
    end

    context 'when the key is empty' do
      let(:assistant_key) { '' }

      it 'refuses every request, even one that sends an empty key' do
        read_identity(key: '')

        expect_error 401, 'INVALID_API_KEY'
      end
    end

    it 'is checked before the token: a wrong key with a wrong token is an API key error' do
      read_identity(key: 'another-key', token: 'unknown')

      expect_error 401, 'INVALID_API_KEY'
    end
  end

  describe 'token of the user' do
    it 'refuses a missing token' do
      read_identity(token: nil)

      expect_error 401, 'INVALID_TOKEN'
    end

    it 'refuses a token sent in the URL only, even a valid one' do
      read_identity(token: nil, params: { token: user.token })

      expect_error 401, 'INVALID_TOKEN'
    end

    it 'ignores a token in the URL when the header holds another one' do
      read_identity(token: 'unknown', params: { token: user.token })

      expect_error 401, 'INVALID_TOKEN'
    end

    it 'refuses a token that matches no account' do
      read_identity(token: 'unknown')

      expect_error 401, 'INVALID_TOKEN'
    end

    it 'refuses an Authorization header that is not a Bearer one' do
      request.headers['X-API-KEY'] = assistant_key
      request.headers['Authorization'] = "Token #{user.token}"

      get :read

      expect_error 401, 'INVALID_TOKEN'
    end

    {
      'deleted' => { deleted: true },
      'blocked' => { validation_status: 'blocked' },
      'temporarily blocked' => { validation_status: 'blocked', unblock_at: 1.week.from_now },
      'anonymized' => { validation_status: 'anonymized' }
    }.each do |label, attributes|
      it "refuses a #{label} account with the very same answer as an unknown token" do
        user.update_columns(attributes)

        read_identity
        refused = [response.status, response.body]
        read_identity(token: 'unknown')

        expect(refused).to eq [401, response.body]
      end
    end

    [
      '1_anonymous_',
      '1_anonymous_abc',
      "1_anonymous_#{'a' * 36}",
      "1_anonymous_#{'a' * 36}_short"
    ].each do |malformed|
      it "refuses the malformed anonymous token #{malformed.inspect} as an invalid token, without error" do
        read_identity(token: malformed)

        expect_error 401, 'INVALID_TOKEN'
      end
    end

    it 'refuses an anonymous account, with a refusal of its own' do
      anonymous_token = AnonymousUserService.token_from_uuid(SecureRandom.uuid, community: $server_community)

      read_identity(token: anonymous_token)

      expect_error 403, 'ANONYMOUS_ACCOUNT'
    end

    it 'recognizes an account that is still pending validation, as the application does' do
      user.update_columns(validation_status: 'pending')

      read_identity

      expect(response.status).to eq 200
      expect(body['id']).to eq user.uuid
    end

    %w[offer_help ask_for_help].each do |goal|
      it "recognizes an account whose goal is #{goal}" do
        user.update_columns(goal: goal)

        read_identity

        expect(response.status).to eq 200
        expect(body['id']).to eq user.uuid
      end
    end
  end

  describe 'identity' do
    before { create :address, user: user, place_name: '12 rue des Lilas', city: 'Lyon' }

    it 'returns the uuid, the first name and the city of the user, and nothing else' do
      read_identity

      expect(response.status).to eq 200
      expect(body).to eq('id' => user.uuid, 'firstName' => 'Camille', 'city' => 'Lyon')
    end

    it 'never returns the label of the address' do
      read_identity

      expect(response.body).not_to include('Lilas')
    end

    it 'returns no personal information other than the three fields' do
      read_identity

      [user.last_name, user.email, user.phone, user.token, user.sms_code].each do |secret|
        expect(response.body).not_to include(secret)
      end
    end

    it 'returns a null city, without error, when the main address has no city' do
      user.address.update_columns(city: nil)

      read_identity

      expect(response.status).to eq 200
      expect(body).to eq('id' => user.uuid, 'firstName' => 'Camille', 'city' => nil)
    end

    it 'returns a null city, without error, when the user has no address' do
      user.update_columns(address_id: nil)

      read_identity

      expect(response.status).to eq 200
      expect(body['city']).to be_nil
    end

    it 'returns a null first name, without error, when it is not filled in' do
      user.update_columns(first_name: '')

      read_identity

      expect(response.status).to eq 200
      expect(body['firstName']).to be_nil
    end

    it 'only ever concerns the user whose token is presented' do
      other = create :public_user, first_name: 'Dominique', token: 'other-user-token'
      create :address, user: other, city: 'Brest'

      read_identity(token: other.token)

      expect(body).to eq('id' => other.uuid, 'firstName' => 'Dominique', 'city' => 'Brest')
    end
  end

  describe 'no effect on the activity of the user' do
    before { user }

    it 'leaves the last sign in untouched' do
      user.update_columns(last_sign_in_at: 1.month.ago)
      before_sign_in = user.reload.last_sign_in_at

      read_identity

      expect(response.status).to eq 200
      expect(user.reload.last_sign_in_at).to eq before_sign_in
    end

    it 'does not synchronize Salesforce, track a session or enqueue a route completion' do
      expect_any_instance_of(User).not_to receive(:sync_salesforce)
      expect(SessionHistory).not_to receive(:track)
      expect(RouteCompletionJob).not_to receive(:perform_async)

      read_identity

      expect(response.status).to eq 200
    end

    it 'writes nothing at all' do
      expect { read_identity }.not_to change { [User.maximum(:updated_at), SessionHistory.count] }
    end

    it 'sets no cookie' do
      read_identity

      expect(response.headers['Set-Cookie']).to be_nil
    end
  end

  describe 'logs' do
    # What Lograge writes for the request: the only trace of it in the logs.
    def logged_line
      io = StringIO.new
      original = Lograge.logger
      Lograge.logger = ActiveSupport::Logger.new(io)
      yield
      io.string
    ensure
      Lograge.logger = original
    end

    it 'carry the uuid of the user, and neither the token, nor the key, nor the first name' do
      line = logged_line { read_identity }

      expect(line).to include(user.uuid)
      expect(line).not_to include(user.token)
      expect(line).not_to include(assistant_key)
      expect(line).not_to include('Camille')
    end

    it 'do not carry a token sent in the URL either: it is refused and the parameters are filtered' do
      line = logged_line { read_identity(token: nil, params: { token: user.token }) }

      expect(line).to include('assistant')
      expect(line).not_to include(user.token)
    end
  end
end
