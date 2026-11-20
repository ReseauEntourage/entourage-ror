require 'rails_helper'

describe Api::V1::Assistant::OutingParticipantsController, type: :controller do
  let(:user) { create :public_user, token: 'user-secret-token' }
  let(:organizer) { create :public_user, first_name: 'Léa', last_name: 'Bernard' }
  let!(:outing) { create :outing, :outing_class, user: organizer }
  let(:body) { JSON.parse(response.body) }

  def call_route(key:, token:, params: {})
    request.headers['X-API-KEY'] = key if key
    request.headers['Authorization'] = "Bearer #{token}" if token
    get :read, params: { id: outing.uuid_v2 }.merge(params)
  end

  it_behaves_like 'an assistant read'

  it 'is routed to GET /api/v1/assistant/outings/:id/participants' do
    expect(get: '/api/v1/assistant/outings/abc/participants').to route_to('api/v1/assistant/outing_participants#read', id: 'abc')
  end

  describe 'the participants' do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('ASSISTANT_API_KEY').and_return('assistant-secret-key')
    end

    def join(person, status: :accepted)
      create :join_request, user: person, joinable: outing, status: status, role: :participant
    end

    it 'returns the accepted participants that the app shows, with exactly these fields' do
      person = create :public_user, first_name: 'Sam', last_name: 'Durand'
      join(person)

      call_route(key: 'assistant-secret-key', token: user.token)

      expect(body['participantsCount']).to eq(2)
      expect(body['participants']).to match_array([
        { 'id' => organizer.uuid, 'displayName' => 'Léa B.', 'groupRole' => 'organizer', 'communityRoles' => [] },
        { 'id' => person.uuid, 'displayName' => 'Sam D.', 'groupRole' => 'participant', 'communityRoles' => [] }
      ])
      expect(response.body).not_to include(person.phone)
    end

    it 'returns neither a cancelled, nor a blocked, nor a deleted participant: the app does not show them' do
      join(create(:public_user, first_name: 'Annulé'), status: :cancelled)
      join(create(:public_user, first_name: 'Bloqué').tap { |u| u.update_attribute(:validation_status, :blocked) })
      join(create(:public_user, first_name: 'Supprimé').tap { |u| u.update_columns(deleted: true) })

      call_route(key: 'assistant-secret-key', token: user.token)

      names = body['participants'].map { |participant| participant['displayName'] }
      expect(names).to eq(['Léa B.'])
    end

    it 'returns the community roles that the app shows' do
      join(create(:public_user, first_name: 'Ana', last_name: 'Petit', targeting_profile: 'ambassador'))

      call_route(key: 'assistant-secret-key', token: user.token)

      ambassador = body['participants'].find { |participant| participant['displayName'] == 'Ana P.' }
      expect(ambassador['communityRoles']).to eq(['Animateur Entourage'])
    end
  end
end

describe Api::V1::Assistant::OutingParticipationController, type: :controller do
  let(:user) { create :public_user, token: 'user-secret-token' }
  let!(:outing) { create :outing, :outing_class }
  let(:body) { JSON.parse(response.body) }

  def call_route(key:, token:, params: {})
    request.headers['X-API-KEY'] = key if key
    request.headers['Authorization'] = "Bearer #{token}" if token
    get :read, params: { id: outing.uuid_v2 }.merge(params)
  end

  it_behaves_like 'an assistant read'

  it 'is routed to GET /api/v1/assistant/outings/:id/participation' do
    expect(get: '/api/v1/assistant/outings/abc/participation').to route_to('api/v1/assistant/outing_participation#read', id: 'abc')
  end

  describe 'the participation' do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('ASSISTANT_API_KEY').and_return('assistant-secret-key')
    end

    def read
      call_route(key: 'assistant-secret-key', token: user.token)
    end

    it 'says that the user did not join' do
      read

      expect(body).to eq('registered' => false, 'confirmed' => false, 'participated' => false)
    end

    it 'says that the user is registered' do
      create :join_request, user: user, joinable: outing, status: :accepted, role: :participant

      read

      expect(body).to eq('registered' => true, 'confirmed' => false, 'participated' => false)
    end

    it 'says that the attendance is already recorded' do
      create :join_request, user: user, joinable: outing, status: :accepted, role: :participant,
                            confirmed_at: 1.day.ago, participate_at: Time.zone.now

      read

      expect(body).to eq('registered' => true, 'confirmed' => true, 'participated' => true)
    end

    it 'does not count a cancelled registration' do
      create :join_request, user: user, joinable: outing, status: :cancelled, role: :participant, participate_at: Time.zone.now

      read

      expect(body).to eq('registered' => false, 'confirmed' => false, 'participated' => false)
    end

    it 'only concerns the user of the token, not another registered member' do
      create :join_request, user: create(:public_user), joinable: outing, status: :accepted, role: :participant

      read

      expect(body['registered']).to eq(false)
    end
  end
end
