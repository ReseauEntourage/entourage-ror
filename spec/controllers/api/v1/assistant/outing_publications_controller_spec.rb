require 'rails_helper'

describe Api::V1::Assistant::OutingPublicationsController, type: :controller do
  let(:user) { create :public_user, token: 'user-secret-token' }
  let(:starts_at) { 5.days.from_now.change(hour: 15) }
  let(:geocoded) do
    double(latitude: 48.8796, longitude: 2.3089, address: '35 Boulevard de Courcelles, 75008 Paris, France', place_id: 'ChIJplace')
  end

  def call_action(key:, api_key:, token:, params:)
    request.headers['X-API-KEY'] = api_key if api_key
    request.headers['Authorization'] = "Bearer #{token}" if token
    request.headers['Idempotency-Key'] = key if key
    post :publish, params: params, as: :json
  end

  let(:valid_params) do
    {
      title: 'Balade au parc', description: 'Bonjour à tous, une balade ensemble.',
      startsAt: starts_at.iso8601, endsAt: (starts_at + 2.hours).iso8601, place: 'Parc Monceau, Paris', reservedFemale: false
    }
  end
  let(:other_params) { valid_params.merge(title: 'Une autre balade') }
  let(:action_type) { 'outing.publish' }
  let(:subject_class) { Entourage }

  before do
    allow(Geocoder).to receive(:search).and_call_original
    allow(Geocoder).to receive(:search).with('Parc Monceau, Paris').and_return([geocoded])
  end

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

    def body
      JSON.parse(response.body)
    end

    it 'creates the outing as the app does, organized by the user, with their words untouched' do
      publish

      outing = Outing.find_by!(uuid_v2: body['id'])
      expect(response.status).to eq(201)
      expect(body).to eq('id' => outing.uuid_v2, 'status' => 'open')
      expect(outing).to have_attributes(user_id: user.id, title: 'Balade au parc', description: 'Bonjour à tous, une balade ensemble.', group_type: 'outing')
      expect(outing.member_ids).to eq([user.id])
      expect(outing.place_name).to eq('Parc Monceau, Paris')
      expect(outing.reserved_female).to be_falsey # the model stores a false as nothing
    end

    it 'geocodes the place for the coordinates that the app requires, and keeps the end given by the assistant' do
      publish

      outing = Outing.find_by!(uuid_v2: body['id'])
      expect([outing.latitude, outing.longitude]).to eq([48.8796, 2.3089])
      expect(outing.street_address).to eq('35 Boulevard de Courcelles, 75008 Paris, France')
      expect(outing.google_place_id).to eq('ChIJplace')
      expect(outing.ends_at.to_time.to_i).to eq((starts_at + 2.hours).to_i)
    end

    it 'creates an outing reserved to women when asked' do
      publish(valid_params.merge(reservedFemale: true))

      expect(Outing.find_by!(uuid_v2: body['id']).reserved_female).to eq(true)
    end

    it 'creates the outing once when the request is replayed' do
      key = SecureRandom.uuid

      expect { 2.times { publish(key: key) } }.to change { Outing.count }.by(1)
    end

    it 'answers 400 PLACE_NOT_FOUND when the geocoder does not know the place, and creates nothing' do
      allow(Geocoder).to receive(:search).with('Nulle part').and_return([])

      expect { publish(valid_params.merge(place: 'Nulle part')) }.not_to change { Outing.count }

      expect([response.status, body.dig('error', 'code')]).to eq([400, 'PLACE_NOT_FOUND'])
      expect(AssistantAction.last).to be_failed
    end

    it 'refuses what the validations of the app refuse: a start in the past, with the reasons' do
      publish(valid_params.merge(startsAt: 2.days.ago.iso8601, endsAt: 1.day.ago.iso8601))

      expect(response.status).to eq(400)
      expect(body['error']).to include('code' => 'CANNOT_PUBLISH')
      expect(body['error']['reasons'].join).to include('starts_at')
      expect(Outing.where(title: 'Balade au parc')).not_to exist
    end

    it 'refuses an outing without title, without start or without place' do
      [:title, :startsAt, :place].each do |field|
        publish(valid_params.merge(field => ''))

        expect([response.status, body.dig('error', 'code')]).to eq([400, 'INVALID_PARAMS'])
      end
    end

    it 'does not accept the fields that the app does not let a member set (status, user)' do
      publish(valid_params.merge(status: 'closed', user_id: create(:public_user).id))

      outing = Outing.find_by!(uuid_v2: body['id'])
      expect(outing).to have_attributes(status: 'open', user_id: user.id)
    end
  end
end
