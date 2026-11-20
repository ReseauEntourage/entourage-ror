require 'rails_helper'

describe Api::V1::Assistant::MemberMessagesController, type: :controller do
  let(:user) { create :public_user, token: 'user-secret-token', first_name: 'Camille' }
  let(:member) { create :public_user, first_name: 'Sam', last_name: 'Durand' }
  let(:text) { "Bonjour Sam,  je m'appelle Camille, c'est ma première fois !" }

  def call_action(key:, api_key:, token:, params:)
    request.headers['X-API-KEY'] = api_key if api_key
    request.headers['Authorization'] = "Bearer #{token}" if token
    request.headers['Idempotency-Key'] = key if key
    post :deliver, params: params, as: :json
  end

  let(:valid_params) { { id: member.uuid, content: text } }
  let(:other_params) { valid_params.merge(content: 'Autre texte') }
  let(:action_type) { 'member.first_message' }
  let(:subject_class) { ChatMessage }

  it_behaves_like 'an assistant action'

  it 'is routed to POST /api/v1/assistant/members/:id/messages' do
    expect(post: '/api/v1/assistant/members/abc/messages').to route_to('api/v1/assistant/member_messages#deliver', id: 'abc')
  end

  context 'when it runs' do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('ASSISTANT_API_KEY').and_return('assistant-secret-key')
      allow(ENV).to receive(:[]).with('ASSISTANT_ACTIONS_ENABLED').and_return('true')
    end

    def deliver(params = valid_params, key: SecureRandom.uuid, token: user.token)
      @controller = described_class.new
      call_action(key: key, api_key: 'assistant-secret-key', token: token, params: params)
    end

    def body
      JSON.parse(response.body)
    end

    it 'sends the text to the member, in a private conversation with the user, untouched' do
      deliver

      message = ChatMessage.find(body['messageId'])
      conversation = Entourage.find_by!(uuid_v2: body['conversationId'])
      expect(response.status).to eq(201)
      expect(message).to have_attributes(user_id: user.id, content: text, message_type: 'text')
      expect(conversation).to have_attributes(group_type: 'conversation')
      expect(conversation.members.pluck(:id)).to match_array([user.id, member.id])
    end

    it 'does not ask the agreement of the member beforehand: both are accepted members of the conversation' do
      deliver

      conversation = Entourage.find_by!(uuid_v2: body['conversationId'])
      expect(conversation.join_requests.pluck(:status).uniq).to eq(['accepted'])
    end

    it 'shows the member the message and nothing else: no metadata, no mention of why or how it was sent' do
      deliver

      message = ChatMessage.find(body['messageId'])
      expect(message.metadata.to_h.except(:$id, '$id')).to be_blank
      serialized = V1::ChatMessages::CommonSerializer.new(message, scope: { user: member }).to_json
      expect(serialized.downcase).not_to include('assistant')
      expect(AssistantAction.last.result.to_json).not_to include(text)
    end

    it 'counts the first message of the person, once, whatever the replays and the next messages' do
      key = SecureRandom.uuid

      deliver(key: key)
      expect(body['firstMessage']).to eq(true)
      expect(AssistantAction.first_messages_count(user)).to eq(1)

      deliver(key: key)
      expect(AssistantAction.first_messages_count(user)).to eq(1)

      deliver(valid_params.merge(content: 'Un deuxième message'))
      expect(body['firstMessage']).to eq(false)
      expect(AssistantAction.first_messages_count(user)).to eq(1)
      expect(AssistantAction.first_messages_count(member)).to eq(0)

      other_member = create :public_user
      deliver(valid_params.merge(id: other_member.uuid))
      expect(AssistantAction.first_messages_count(user)).to eq(2)
    end

    it 'sends the message once when the request is replayed' do
      key = SecureRandom.uuid

      expect { 2.times { deliver(key: key) } }.to change { ChatMessage.count }.by(1)
    end

    it 'writes in the existing conversation of the two members' do
      conversation = create :conversation, participants: [user, member]

      deliver

      expect(body['conversationId']).to eq(conversation.reload.uuid_v2)
      expect(Entourage.where(group_type: :conversation).count).to eq(1)
    end

    it 'refuses a member that cannot be written to, always with the same answer' do
      deleted = create(:public_user).tap { |u| u.update_columns(deleted: true) }
      blocked = create(:public_user).tap { |u| u.update_columns(validation_status: 'blocked') }
      anonymized = create(:public_user).tap { |u| u.update_columns(validation_status: 'anonymized') }
      blocked_the_user = create :public_user
      UserBlockedUser.create!(user_id: blocked_the_user.id, blocked_user_id: user.id)
      blocked_by_the_user = create :public_user
      UserBlockedUser.create!(user_id: user.id, blocked_user_id: blocked_by_the_user.id)

      answers = [user.uuid, 'unknown', deleted.uuid, blocked.uuid, anonymized.uuid, blocked_the_user.uuid, blocked_by_the_user.uuid].map do |id|
        deliver(valid_params.merge(id: id))
        [response.status, response.body]
      end

      expect(answers.uniq).to eq([[404, { error: { code: 'RECIPIENT_UNAVAILABLE', message: 'This member cannot be written to.' } }.to_json]])
      expect(ChatMessage.count).to eq(0)
    end

    it 'refuses a message without text' do
      deliver(valid_params.merge(content: ''))

      expect([response.status, body.dig('error', 'code')]).to eq([400, 'INVALID_PARAMS'])
    end
  end
end

describe Api::V1::Assistant::OrganizerMessagesController, type: :controller do
  let(:user) { create :public_user, token: 'user-secret-token' }
  let(:organizer) { create :public_user, first_name: 'Léa', last_name: 'Bernard' }
  let!(:outing) { create :outing, :outing_class, user: organizer }

  def call_action(key:, api_key:, token:, params:)
    request.headers['X-API-KEY'] = api_key if api_key
    request.headers['Authorization'] = "Bearer #{token}" if token
    request.headers['Idempotency-Key'] = key if key
    post :deliver, params: params, as: :json
  end

  let(:valid_params) { { id: outing.uuid_v2, kind: 'first_time', content: 'Bonjour, ce sera ma première fois.' } }
  let(:other_params) { valid_params.merge(kind: 'question', content: 'Autre texte') }
  let(:action_type) { 'outing.notify_organizer' }
  let(:subject_class) { ChatMessage }

  it_behaves_like 'an assistant action'

  it 'is routed to POST /api/v1/assistant/outings/:id/organizer_messages' do
    expect(post: '/api/v1/assistant/outings/abc/organizer_messages').to route_to('api/v1/assistant/organizer_messages#deliver', id: 'abc')
  end

  context 'when it runs' do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('ASSISTANT_API_KEY').and_return('assistant-secret-key')
      allow(ENV).to receive(:[]).with('ASSISTANT_ACTIONS_ENABLED').and_return('true')
    end

    def notify(params = valid_params, key: SecureRandom.uuid)
      @controller = described_class.new
      call_action(key: key, api_key: 'assistant-secret-key', token: user.token, params: params)
    end

    it 'sends the message to the organizer of the outing, as the user' do
      notify

      body = JSON.parse(response.body)
      message = ChatMessage.find(body['messageId'])
      expect(response.status).to eq(201)
      expect(body).to include('outingId' => outing.uuid_v2, 'kind' => 'first_time', 'firstMessage' => true)
      expect(message).to have_attributes(user_id: user.id, content: 'Bonjour, ce sera ma première fois.')
      expect(message.messageable.members.pluck(:id)).to match_array([user.id, organizer.id])
    end

    %w[first_time question safety_signal].each do |kind|
      it "accepts the kind #{kind}" do
        notify(valid_params.merge(kind: kind))

        expect(response.status).to eq(201)
      end
    end

    it 'refuses an unknown kind, an unknown outing, and the organizer writing to themselves' do
      notify(valid_params.merge(kind: 'spam'))
      expect([response.status, JSON.parse(response.body).dig('error', 'code')]).to eq([400, 'INVALID_PARAMS'])

      notify(valid_params.merge(id: 'unknown'))
      expect([response.status, JSON.parse(response.body).dig('error', 'code')]).to eq([404, 'NOT_FOUND'])

      @controller = described_class.new
      call_action(key: SecureRandom.uuid, api_key: 'assistant-secret-key', token: organizer.token, params: valid_params)
      expect(response.status).to eq(400)
    end

    it 'sends once when the request is replayed' do
      key = SecureRandom.uuid

      expect { 2.times { notify(key: key) } }.to change { ChatMessage.count }.by(1)
    end
  end
end

# Spike EN-9878 (task 4.4): does a blocked member receive the message? No: blocking is kept in
# user_blocked_users, and ChatMessage refuses any message of a private conversation in which one of the
# two members blocked the other, in either direction. The assistant refuses it too, without revealing
# the block (Assistant::Actions::Base#find_recipient!).
describe 'a message in a private conversation where one member blocked the other, in the app' do
  let(:sender) { create :public_user }
  let(:recipient) { create :public_user }

  def send_message
    conversation = ChatServices::ChatMessageBuilder.find_conversation(recipient.id, user_id: sender.id)
    join_request = conversation.join_requests.to_a.find { |request| request.user_id == sender.id }
    failed = nil

    ChatServices::ChatMessageBuilder.new(
      params: { content: 'Bonjour' }, user: sender, joinable: conversation, join_request: join_request
    ).create { |on| on.failure { |message| failed = message } }

    failed
  end

  it 'is refused when the recipient blocked the sender' do
    UserBlockedUser.create!(user_id: recipient.id, blocked_user_id: sender.id)

    expect(send_message.errors.full_messages.join).to include('bloquée')
    expect(ChatMessage.count).to eq(0)
  end

  it 'is refused when the sender blocked the recipient' do
    UserBlockedUser.create!(user_id: sender.id, blocked_user_id: recipient.id)

    expect(send_message.errors.full_messages.join).to include('bloquée')
    expect(ChatMessage.count).to eq(0)
  end
end
