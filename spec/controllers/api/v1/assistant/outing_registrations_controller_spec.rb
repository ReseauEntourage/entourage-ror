require 'rails_helper'

describe Api::V1::Assistant::OutingRegistrationsController, type: :controller do
  let(:user) { create :public_user, token: 'user-secret-token' }
  let(:organizer) { create :public_user }
  let!(:outing) { create :outing, :outing_class, user: organizer, title: 'Café partagé' }

  def membership
    JoinRequest.find_by(joinable: outing, user: user)
  end

  describe 'register' do
    def call_action(key:, api_key:, token:, params:)
      request.headers['X-API-KEY'] = api_key if api_key
      request.headers['Authorization'] = "Bearer #{token}" if token
      request.headers['Idempotency-Key'] = key if key
      post :register, params: params, as: :json
    end

    let(:valid_params) { { id: outing.uuid_v2 } }
    let(:other_params) { { id: create(:outing, :outing_class, user: organizer).uuid_v2 } }
    let(:action_type) { 'outing.join' }
    let(:subject_class) { JoinRequest }

    it_behaves_like 'an assistant action'

    it 'is routed to POST /api/v1/assistant/outings/:id/register and unregister' do
      expect(post: '/api/v1/assistant/outings/abc/register').to route_to('api/v1/assistant/outing_registrations#register', id: 'abc')
      expect(post: '/api/v1/assistant/outings/abc/unregister').to route_to('api/v1/assistant/outing_registrations#unregister', id: 'abc')
    end

    describe 'the registration' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('ASSISTANT_API_KEY').and_return('assistant-secret-key')
        allow(ENV).to receive(:[]).with('ASSISTANT_ACTIONS_ENABLED').and_return('true')
      end

      def join(key: SecureRandom.uuid, id: outing.uuid_v2)
        @controller = described_class.new
        call_action(key: key, api_key: 'assistant-secret-key', token: user.token, params: { id: id })
      end

      it 'registers the user as the app does' do
        join

        expect(response.status).to eq(201)
        expect(JSON.parse(response.body)).to eq('outingId' => outing.uuid_v2, 'status' => 'registered')
        expect(membership).to have_attributes(status: 'accepted', role: 'participant')
        expect(outing.reload.member_ids).to match_array([organizer.id, user.id])
      end

      it 'has the same effects as the app: the organizer is notified once' do
        expect_any_instance_of(PushNotificationTrigger).to receive(:notify).with(hash_including(sender_id: user.id, users: [organizer])).once

        join
      end

      it 'registers once when the request is replayed with the same key, with or without notification' do
        key = SecureRandom.uuid
        expect_any_instance_of(PushNotificationTrigger).to receive(:notify).once

        join(key: key)
        join(key: key)

        expect(JoinRequest.where(joinable: outing, user: user).count).to eq(1)
      end

      it 'keeps a single registration, and notifies nobody again, when the same person is registered with another key' do
        expect_any_instance_of(PushNotificationTrigger).to receive(:notify).once

        join
        join

        expect(JoinRequest.where(joinable: outing, user: user).count).to eq(1)
        expect(response.status).to eq(201)
        expect(AssistantAction.where(user_id: user.id).count).to eq(2)
      end

      it 'lets the team find that the registration comes from the assistant, and shows the other members no difference' do
        join

        row = AssistantAction.find_by!(subject_type: 'JoinRequest', subject_id: membership.id)
        expect(row).to have_attributes(user_id: user.id, action_type: 'outing.join')

        from_app = create(:public_user).tap { |other| create :join_request, user: other, joinable: outing, status: :accepted, role: :participant }
        shown = [membership, JoinRequest.find_by(joinable: outing, user: from_app)].map do |join_request|
          V1::JoinRequestSerializer.new(join_request, scope: { user: organizer }, root: false).as_json
        end
        expect(shown.first.keys).to eq(shown.last.keys)
        expect(shown.to_json.downcase).not_to include('assistant')
        expect(JoinRequest.column_names).not_to include('assistant_action_id', 'via_assistant')
      end

      it 'registers again a user who cancelled, as the app does' do
        create :join_request, user: user, joinable: outing, status: :cancelled, role: :participant

        join

        expect(membership.status).to eq('accepted')
      end

      it 'refuses an unknown outing, or one that the app hides from the user' do
        join(id: 'unknown')
        expect([response.status, JSON.parse(response.body).dig('error', 'code')]).to eq([404, 'NOT_FOUND'])

        hidden = create :outing, :outing_class, user: organizer, exclusive_to: 'offer_help'
        user.update_columns(goal: 'ask_for_help')
        join(id: hidden.uuid_v2)
        expect(response.status).to eq(404)
        expect(JoinRequest.where(joinable: hidden, user: user)).not_to exist
      end

      it 'refuses what the validations of the app refuse' do
        allow_any_instance_of(JoinRequest).to receive(:save).and_wrap_original do |original, *args|
          original.receiver.errors.add(:base, 'refused by the app')
          false
        end

        join

        expect(response.status).to eq(400)
        expect(JSON.parse(response.body)['error']).to include('code' => 'CANNOT_JOIN', 'reasons' => ['refused by the app'])
        expect(AssistantAction.last).to be_failed
      end

      # Spike 1.1: the app refuses neither a full outing nor an outing reserved to women. The action
      # has "the same refusals as the app", so it does not either; the rule on gender waits for
      # the product decision (design.md, "Événements réservés aux femmes").
      it 'registers to a full outing, as the app does' do
        full = create :outing, :outing_class, user: organizer, metadata: { place_limit: 1 }
        join(id: full.uuid_v2)

        expect(response.status).to eq(201)
      end

      it 'registers a man or a person without gender to an outing reserved to women, as the app does' do
        reserved = create :outing, :outing_class, user: organizer, metadata: { reserved_female: true }
        user.update!(gender: 'male')

        join(id: reserved.uuid_v2)

        expect(response.status).to eq(201)
      end
    end
  end

  describe 'unregister' do
    def call_action(key:, api_key:, token:, params:)
      request.headers['X-API-KEY'] = api_key if api_key
      request.headers['Authorization'] = "Bearer #{token}" if token
      request.headers['Idempotency-Key'] = key if key
      post :unregister, params: params, as: :json
    end

    let(:valid_params) { { id: outing.uuid_v2 } }
    let(:other_params) { { id: create(:outing, :outing_class, user: organizer).uuid_v2 } }
    let(:action_type) { 'outing.leave' }
    let(:subject_class) { JoinRequest }

    before { create :join_request, user: user, joinable: outing, status: :accepted, role: :participant }

    it_behaves_like 'an assistant action'

    it 'cancels the registration with the same effects as the app' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('ASSISTANT_API_KEY').and_return('assistant-secret-key')
      allow(ENV).to receive(:[]).with('ASSISTANT_ACTIONS_ENABLED').and_return('true')

      call_action(key: SecureRandom.uuid, api_key: 'assistant-secret-key', token: user.token, params: { id: outing.uuid_v2 })

      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)).to eq('outingId' => outing.uuid_v2, 'status' => 'unregistered')
      expect(membership.status).to eq('cancelled')
      expect(outing.reload.member_ids).to eq([organizer.id])
    end

    it 'refuses when the user was not registered, and refuses the organizer to leave their own outing' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('ASSISTANT_API_KEY').and_return('assistant-secret-key')
      allow(ENV).to receive(:[]).with('ASSISTANT_ACTIONS_ENABLED').and_return('true')
      stranger = create :public_user

      call_action(key: SecureRandom.uuid, api_key: 'assistant-secret-key', token: stranger.token, params: { id: outing.uuid_v2 })
      expect([response.status, JSON.parse(response.body).dig('error', 'code')]).to eq([404, 'NOT_REGISTERED'])

      @controller = described_class.new
      call_action(key: SecureRandom.uuid, api_key: 'assistant-secret-key', token: organizer.token, params: { id: outing.uuid_v2 })
      expect([response.status, JSON.parse(response.body).dig('error', 'code')]).to eq([400, 'CANNOT_LEAVE'])
    end
  end
end
