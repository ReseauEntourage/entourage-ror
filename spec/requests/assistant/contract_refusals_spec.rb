require 'rails_helper'

# The refusals that the assistant knows how to handle (EN-9878, contract test): the real answers of the
# controllers, written as snapshots. They complete the requests that the assistant sends
# (spec/requests/assistant/contract_spec.rb).
describe 'Assistant contract: refusals and special answers', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create :public_user, token: 'user-secret-token', first_name: 'Camille', last_name: 'Dupont' }
  let(:organizer) { create :public_user, first_name: 'Léa', last_name: 'Bernard' }
  let!(:outing) { create :outing, :outing_class, user: organizer, title: 'Café partagé' }
  let(:key) { 'a1b2c3d4-0000-4000-8000-000000000001' }
  let(:actions_enabled) { 'true' }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('ASSISTANT_API_KEY').and_return(AssistantContractHelper::API_KEY)
    allow(ENV).to receive(:[]).with('ASSISTANT_ACTIONS_ENABLED').and_return(actions_enabled)
  end

  def aliases
    { user.uuid => '<user-uuid>', outing.uuid_v2 => '<outing-id>', organizer.uuid => '<organizer-uuid>', key => '<key>' }
  end

  def register(token: user.token, key: self.key)
    send_as_assistant(:post, "/api/v1/assistant/outings/#{outing.uuid_v2}/register", token: token, body: {}, key: key)
  end

  def code
    JSON.parse(response.body).dig('error', 'code')
  end

  describe 'a category of help that does not exist in /help_categories' do
    before { create :address, user: user, city: 'Lyon', latitude: 45.764, longitude: 4.8357 }

    def publish path, body, index
      send_as_assistant(:post, "/api/v1/assistant/#{path}", token: user.token, body: body, key: format('a1b2c3d4-0000-4000-8000-%012d', index))
    end

    { 'unknown' => '3', 'empty' => '', 'absent' => nil }.each_with_index do |(name, value), index|
      %w[help_requests help_offers].each do |path|
        it "400 INVALID_PARAMS and nothing created: #{path} with a #{name} category" do
          body = { title: 'Aide', description: 'Un coup de main', category: value }.compact
          expect { publish(path, body, index) }.not_to change { Action.unscoped.where(user_id: user.id).count }

          expect(response.status).to eq(400)
          expect(code).to eq('INVALID_PARAMS')
          expect(JSON.parse(response.body).dig('error', 'reasons').to_s).to match(/category/)
          check_snapshot "refusal-#{path.singularize}-#{name}-category", aliases: aliases.merge(format('a1b2c3d4-0000-4000-8000-%012d', index) => '<key>')
        end
      end
    end

    it '200 with an empty list: a search of help requests in a category that does not exist' do
      send_as_assistant(:get, '/api/v1/assistant/help_requests', token: user.token, query: { category: '3' })

      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)).to eq('items' => [])
      check_snapshot 'refusal-help-search-unknown-category', aliases: aliases
    end
  end

  it '404 RECIPIENT_UNAVAILABLE: a member who cannot be written to' do
    member = create :public_user
    UserBlockedUser.create!(user_id: member.id, blocked_user_id: user.id)

    send_as_assistant(:post, "/api/v1/assistant/members/#{member.uuid}/messages", token: user.token, body: { message: 'Bonjour' }, key: key)

    expect([response.status, code]).to eq([404, 'RECIPIENT_UNAVAILABLE'])
    check_snapshot 'refusal-recipient-unavailable', aliases: aliases.merge(member.uuid => '<member-uuid>')
  end

  it '403 NOT_A_MEMBER: a message in the discussion of an outing the user is not registered to' do
    send_as_assistant(:post, "/api/v1/assistant/outings/#{outing.uuid_v2}/discussion_messages", token: user.token, body: { message: 'Bonjour' }, key: key)

    expect([response.status, code]).to eq([403, 'NOT_A_MEMBER'])
    check_snapshot 'refusal-not-a-member', aliases: aliases
  end

  it '400 PLACE_NOT_FOUND: an outing whose place the geocoder does not know' do
    allow(Geocoder).to receive(:search).and_call_original
    allow(Geocoder).to receive(:search).with('Nulle part').and_return([])
    starts_at = 5.days.from_now

    send_as_assistant(:post, '/api/v1/assistant/outings', token: user.token, key: key,
                      body: { title: 'Balade', description: 'Une balade', startsAt: starts_at.iso8601, endsAt: (starts_at + 2.hours).iso8601, place: 'Nulle part', reservedFemale: false })

    expect([response.status, code]).to eq([400, 'PLACE_NOT_FOUND'])
    check_snapshot 'refusal-place-not-found', aliases: aliases
  end

  it '404 PLACE_NOT_FOUND on a read: a city that the geocoder does not know' do
    allow(Geocoder).to receive(:search).and_call_original
    allow(Geocoder).to receive(:search).with('Atlantis').and_return([])
    create :address, user: user, city: 'Paris', latitude: 48.8566, longitude: 2.3522

    send_as_assistant(:get, '/api/v1/assistant/outings', token: user.token, query: { city: 'Atlantis' })

    expect([response.status, code]).to eq([404, 'PLACE_NOT_FOUND'])
    check_snapshot 'refusal-place-not-found-read', aliases: aliases
  end

  describe 'a row that stays processing' do
    let(:digest) do
      Assistant::ActionRunner.new(user: user, key: key, action_type: 'outing.join', payload: { outing: outing.uuid_v2 }).send(:digest)
    end

    before { AssistantAction.create!(user: user, idempotency_key: key, action_type: 'outing.join', request_digest: digest) }

    it '409 ACTION_IN_PROGRESS before 2 minutes' do
      travel(90.seconds) { register }

      expect([response.status, code]).to eq([409, 'ACTION_IN_PROGRESS'])
      check_snapshot 'refusal-action-in-progress', aliases: aliases
    end

    it '410 ACTION_EXPIRED after 2 minutes, and the registration is never made under this key' do
      travel(121.seconds) { register }

      expect([response.status, code]).to eq([410, 'ACTION_EXPIRED'])
      expect(JoinRequest.where(joinable: outing, user: user)).not_to exist
      check_snapshot 'refusal-action-expired', aliases: aliases
    end
  end

  it '422 IDEMPOTENCY_KEY_REUSED: the same key for another request' do
    register
    send_as_assistant(:post, "/api/v1/assistant/outings/#{create(:outing, :outing_class, user: organizer).uuid_v2}/register", token: user.token, body: {}, key: key)

    expect([response.status, code]).to eq([422, 'IDEMPOTENCY_KEY_REUSED'])
    check_snapshot 'refusal-key-reused', aliases: aliases
  end

  it '400 IDEMPOTENCY_KEY_REQUIRED: an action without key' do
    register(key: nil)

    expect([response.status, code]).to eq([400, 'IDEMPOTENCY_KEY_REQUIRED'])
    check_snapshot 'refusal-key-required', aliases: aliases
  end

  context 'when the actions are switched off' do
    let(:actions_enabled) { nil }

    it '503 ACTIONS_DISABLED, and the reads are not affected' do
      register

      expect([response.status, code]).to eq([503, 'ACTIONS_DISABLED'])
      check_snapshot 'refusal-actions-disabled', aliases: aliases

      send_as_assistant(:get, '/api/v1/assistant/profile', token: user.token)
      expect(response.status).to eq(200)
    end
  end

  it '201 not_delivered: an alert that Slack did not receive is not a success' do
    stub_request(:post, 'https://url.to.slack.com').to_timeout
    allow(Sentry).to receive(:capture_exception)

    send_as_assistant(:post, '/api/v1/assistant/alerts', token: user.token, body: { audience: 'team', message: 'Je ne me sens pas en sécurité.' }, key: key)

    expect(response.status).to eq(201)
    expect(JSON.parse(response.body)['status']).to eq('not_delivered')
    check_snapshot 'special-alert-not-delivered', aliases: aliases
  end

  it '2xx with Idempotent-Replayed: true: a replayed request answers the first result and does nothing' do
    register
    first = JSON.parse(response.body)

    expect { register }.not_to change { JoinRequest.count }

    expect(response.status).to eq(201)
    expect(JSON.parse(response.body)).to eq(first)
    expect(response.headers['Idempotent-Replayed']).to eq('true')
    check_snapshot 'special-replayed', aliases: aliases
  end

  it '401 INVALID_API_KEY and 401 INVALID_TOKEN and 403 ANONYMOUS_ACCOUNT' do
    send_as_assistant(:get, '/api/v1/assistant/profile', token: user.token, api_key: 'wrong')
    expect([response.status, code]).to eq([401, 'INVALID_API_KEY'])
    check_snapshot 'refusal-invalid-api-key'

    send_as_assistant(:get, '/api/v1/assistant/profile', token: 'unknown')
    expect([response.status, code]).to eq([401, 'INVALID_TOKEN'])
    check_snapshot 'refusal-invalid-token'

    send_as_assistant(:get, '/api/v1/assistant/profile', token: AnonymousUserService.token_from_uuid(SecureRandom.uuid, community: $server_community))
    expect([response.status, code]).to eq([403, 'ANONYMOUS_ACCOUNT'])
    check_snapshot 'refusal-anonymous-account'
  end
end
