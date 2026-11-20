require 'rails_helper'

describe Api::V1::Assistant::OutingPublicationsController, type: :controller do
  let(:user) { create :public_user, token: 'user-secret-token' }
  let(:starts_at) { 5.days.from_now.change(hour: 15) }

  def call_action(key:, api_key:, token:, params:)
    request.headers['X-API-KEY'] = api_key if api_key
    request.headers['Authorization'] = "Bearer #{token}" if token
    request.headers['Idempotency-Key'] = key if key
    post :publish, params: params, as: :json
  end

  let(:valid_params) do
    {
      title: 'Balade au parc', description: 'Bonjour à tous, une balade ensemble.', latitude: 48.85, longitude: 2.35,
      metadata: { starts_at: starts_at.iso8601, ends_at: (starts_at + 2.hours).iso8601, place_name: 'Parc Monceau', street_address: '35 Boulevard de Courcelles, 75008 Paris, France', google_place_id: 'foobar' }
    }
  end
  let(:other_params) { valid_params.merge(title: 'Une autre balade') }
  let(:action_type) { 'outing.publish' }
  let(:subject_class) { Entourage }

  it_behaves_like 'an assistant action'

  it 'is routed to POST /api/v1/assistant/outings' do
    expect(post: '/api/v1/assistant/outings').to route_to('api/v1/assistant/outing_publications#publish')
  end

  context 'when it runs' do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('ASSISTANT_API_KEY').and_return('assistant-secret-key')
      allow(ENV).to receive(:[]).with('ASSISTANT_ACTIONS_ENABLED').and_return('true')
    end

    def publish(params = valid_params, key: SecureRandom.uuid)
      @controller = described_class.new
      call_action(key: key, api_key: 'assistant-secret-key', token: user.token, params: params)
    end

    it 'creates the outing as the app does, organized by the user, with their words untouched' do
      publish

      outing = Outing.find_by!(uuid_v2: JSON.parse(response.body)['id'])
      expect(response.status).to eq(201)
      expect(JSON.parse(response.body)).to eq('id' => outing.uuid_v2, 'status' => 'open')
      expect(outing).to have_attributes(user_id: user.id, title: 'Balade au parc', description: 'Bonjour à tous, une balade ensemble.', group_type: 'outing')
      expect(outing.member_ids).to eq([user.id])
      expect(outing.place_name).to eq('Parc Monceau')
    end

    it 'creates the outing once when the request is replayed' do
      key = SecureRandom.uuid

      expect { 2.times { publish(key: key) } }.to change { Outing.count }.by(1)
    end

    it 'refuses what the validations of the app refuse: a start in the past, with the reasons' do
      publish(valid_params.deep_merge(metadata: { starts_at: 2.days.ago.iso8601, ends_at: 1.day.ago.iso8601 }))

      expect(response.status).to eq(400)
      expect(JSON.parse(response.body)['error']).to include('code' => 'CANNOT_PUBLISH')
      expect(JSON.parse(response.body)['error']['reasons'].join).to include('starts_at')
      expect(Outing.where(title: 'Balade au parc')).not_to exist
      expect(AssistantAction.last).to be_failed
    end

    it 'refuses an outing without title' do
      publish(valid_params.merge(title: ''))

      expect([response.status, JSON.parse(response.body).dig('error', 'code')]).to eq([400, 'INVALID_PARAMS'])
    end

    it 'does not accept the fields that the app does not let a member set (status, user)' do
      publish(valid_params.merge(status: 'closed', user_id: create(:public_user).id))

      outing = Outing.find_by!(uuid_v2: JSON.parse(response.body)['id'])
      expect(outing).to have_attributes(status: 'open', user_id: user.id)
    end
  end
end
