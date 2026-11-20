require 'rails_helper'

# The base of the routes through which the assistant acts: the switch, then the idempotency.
describe Api::V1::Assistant::ActionsController, type: :controller do
  let(:assistant_key) { 'assistant-secret-key' }
  let(:user) { create :public_user, token: 'user-secret-token' }
  let(:body) { JSON.parse(response.body) }
  let(:actions_enabled) { 'true' }

  controller(Api::V1::Assistant::ActionsController) do
    cattr_accessor :executions, default: 0

    def act
      run_action('test.act', { text: params[:text] }) do
        self.class.executions += 1
        ::Assistant::ActionRunner::Outcome.new(status: 201, body: { id: 42, status: 'done' }, subject: nil)
      end
    end
  end

  before do
    routes.draw { post 'act' => 'api/v1/assistant/actions#act' }
    controller.class.executions = 0

    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('ASSISTANT_API_KEY').and_return(assistant_key)
    allow(ENV).to receive(:[]).with('ASSISTANT_ACTIONS_ENABLED').and_return(actions_enabled)
  end

  def act(key: SecureRandom.uuid, text: 'hello', api_key: assistant_key, token: user.token)
    request.headers['X-API-KEY'] = api_key if api_key
    request.headers['Authorization'] = "Bearer #{token}" if token
    request.headers['Idempotency-Key'] = key if key
    post :act, params: { text: text }
  end

  describe 'the switch ASSISTANT_ACTIONS_ENABLED' do
    context 'when it is not set' do
      let(:actions_enabled) { nil }

      it 'refuses the action with a 503 ACTIONS_DISABLED and does nothing' do
        act

        expect(response.status).to eq(503)
        expect(body.dig('error', 'code')).to eq('ACTIONS_DISABLED')
        expect(controller.class.executions).to eq(0)
        expect(AssistantAction.count).to eq(0)
      end
    end

    %w[false 0 off].each do |value|
      context "when it is #{value}" do
        let(:actions_enabled) { value }

        it 'refuses the action' do
          act

          expect(response.status).to eq(503)
        end
      end
    end

    context 'when it is true' do
      it 'runs the action' do
        act

        expect(response.status).to eq(201)
        expect(controller.class.executions).to eq(1)
      end
    end

    context 'when it is off and the request has no API key' do
      let(:actions_enabled) { 'false' }

      it 'refuses it as any request without key, not as a disabled action' do
        act(api_key: nil)

        expect(response.status).to eq(401)
        expect(body.dig('error', 'code')).to eq('INVALID_API_KEY')
      end
    end

    context 'when it is off and the token is invalid' do
      let(:actions_enabled) { 'false' }

      it 'refuses it as an invalid token' do
        act(token: 'unknown')

        expect(body.dig('error', 'code')).to eq('INVALID_TOKEN')
      end
    end
  end

  describe 'logs' do
    def logged_line
      io = StringIO.new
      original = Lograge.logger
      Lograge.logger = ActiveSupport::Logger.new(io)
      yield
      io.string
    ensure
      Lograge.logger = original
    end

    it 'carry the type of the action, its result and whether it was replayed, never its content' do
      key = SecureRandom.uuid
      first = logged_line { act(key: key, text: 'A very private sentence') }
      second = logged_line { act(key: key, text: 'A very private sentence') }

      expect(first).to include('"assistant_action":"test.act"', '"assistant_result":"succeeded"', '"assistant_replayed":false')
      expect(second).to include('"assistant_action":"test.act"', '"assistant_result":"succeeded"', '"assistant_replayed":true')
      expect(first + second).not_to include('very private')
      expect(first + second).not_to include(key)
    end
  end

  describe 'the idempotency of the action' do
    it 'refuses an action without key with a 400 IDEMPOTENCY_KEY_REQUIRED and does nothing' do
      act(key: nil)

      expect(response.status).to eq(400)
      expect(body.dig('error', 'code')).to eq('IDEMPOTENCY_KEY_REQUIRED')
      expect(controller.class.executions).to eq(0)
    end

    it 'runs the action once and answers the same thing to a replayed request' do
      key = SecureRandom.uuid
      act(key: key)
      first = [response.status, response.body]
      act(key: key)

      expect([response.status, response.body]).to eq(first)
      expect(response.headers['Idempotent-Replayed']).to eq('true')
      expect(controller.class.executions).to eq(1)
    end
  end
end

describe Api::V1::Assistant::IdentityController, type: :controller do
  let(:user) { create :public_user, first_name: 'Camille', token: 'user-secret-token' }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('ASSISTANT_API_KEY').and_return('assistant-secret-key')
    allow(ENV).to receive(:[]).with('ASSISTANT_ACTIONS_ENABLED').and_return('false')
  end

  it 'still serves the reads when the actions are disabled' do
    request.headers['X-API-KEY'] = 'assistant-secret-key'
    request.headers['Authorization'] = "Bearer #{user.token}"

    get :read

    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['id']).to eq(user.uuid)
  end
end
