require 'rails_helper'

describe Api::V1::Assistant::DiscussionMessagesController, type: :controller do
  let(:user) { create :public_user, token: 'user-secret-token' }
  let(:organizer) { create :public_user }
  let!(:outing) { create :outing, :outing_class, user: organizer }
  let(:text) { "Bonjour à toutes et à tous,  je suis Camille, ravie de venir !" }

  def call_action(key:, api_key:, token:, params:)
    request.headers['X-API-KEY'] = api_key if api_key
    request.headers['Authorization'] = "Bearer #{token}" if token
    request.headers['Idempotency-Key'] = key if key
    post :deliver, params: params, as: :json
  end

  let(:valid_params) { { id: outing.uuid_v2, message: text } }
  let(:other_params) { valid_params.merge(message: 'Autre texte') }
  let(:action_type) { 'outing.discussion_message' }
  let(:subject_class) { ChatMessage }

  before { create :join_request, user: user, joinable: outing, status: :accepted, role: :participant }

  it_behaves_like 'an assistant action'

  it 'is routed to POST /api/v1/assistant/outings/:id/discussion_messages' do
    expect(post: '/api/v1/assistant/outings/abc/discussion_messages').to route_to('api/v1/assistant/discussion_messages#deliver', id: 'abc')
  end

  context 'when it runs' do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('ASSISTANT_API_KEY').and_return('assistant-secret-key')
      allow(ENV).to receive(:[]).with('ASSISTANT_ACTIONS_ENABLED').and_return('true')
    end

    def post_message(params = valid_params, key: SecureRandom.uuid, token: user.token)
      @controller = described_class.new
      call_action(key: key, api_key: 'assistant-secret-key', token: token, params: params)
    end

    def body
      JSON.parse(response.body)
    end

    it 'posts the text in the discussion of the outing, as the user, untouched' do
      post_message

      message = ChatMessage.find(body['messageId'])
      expect(response.status).to eq(201)
      expect(body).to eq('messageId' => message.id, 'outingId' => outing.uuid_v2)
      expect(message).to have_attributes(user_id: user.id, content: text, messageable_id: outing.id)
      expect(outing.chat_messages.pluck(:id)).to include(message.id)
    end

    it 'posts once when the request is replayed' do
      key = SecureRandom.uuid

      expect { 2.times { post_message(key: key) } }.to change { ChatMessage.count }.by(1)
    end

    it 'refuses with 403 NOT_A_MEMBER a user who is not registered to the outing, and a cancelled registration' do
      stranger = create :public_user, token: 'stranger-token'
      post_message(token: stranger.token)
      expect([response.status, body.dig('error', 'code')]).to eq([403, 'NOT_A_MEMBER'])

      JoinRequest.find_by(joinable: outing, user: user).update!(status: :cancelled)
      post_message
      expect([response.status, body.dig('error', 'code')]).to eq([403, 'NOT_A_MEMBER'])
      expect(ChatMessage.count).to eq(0)
    end

    it 'refuses an unknown outing and an empty message' do
      post_message(valid_params.merge(id: 'unknown'))
      expect([response.status, body.dig('error', 'code')]).to eq([404, 'NOT_FOUND'])

      post_message(valid_params.merge(message: ' '))
      expect([response.status, body.dig('error', 'code')]).to eq([400, 'INVALID_PARAMS'])
    end
  end
end
