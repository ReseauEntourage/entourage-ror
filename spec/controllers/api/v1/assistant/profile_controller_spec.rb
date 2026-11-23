require 'rails_helper'

describe Api::V1::Assistant::ProfileController, type: :controller do
  let(:user) do
    create :public_user, token: 'user-secret-token', goal: 'offer_help', travel_distance: 15,
                         interests: %w[sport jeux], availability: { '2' => ['09:00-12:00'] }, gender: 'female'
  end
  # not a `let`: several requests are made in some examples
  def body
    JSON.parse(response.body)
  end

  def call_route(key:, token:, params: {})
    @controller = described_class.new # a controller keeps what it memoized from a previous request
    request.headers['X-API-KEY'] = key if key
    request.headers['Authorization'] = "Bearer #{token}" if token
    get :read, params: params
  end

  it_behaves_like 'an assistant read'

  it 'is routed to GET /api/v1/assistant/profile' do
    expect(get: '/api/v1/assistant/profile').to route_to('api/v1/assistant/profile#read')
  end

  describe 'the profile' do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('ASSISTANT_API_KEY').and_return('assistant-secret-key')
      create :address, user: user, city: 'Lyon'
    end

    it 'returns the declared preferences, and exactly these fields' do
      call_route(key: 'assistant-secret-key', token: user.token)

      expect(body).to eq(
        'city' => 'Lyon',
        'distanceKm' => 15,
        'goal' => 'give-help',
        'interests' => %w[sport jeux],
        'availabilities' => ['tuesday 09:00-12:00'],
        'gender' => 'woman'
      )
    end

    it 'returns the gender as missing when it is not filled in, or is the answer "not given"' do
      [nil, 'secret'].each do |value|
        user.update_columns(options: user.options.to_h.merge('gender' => value))
        call_route(key: 'assistant-secret-key', token: user.token)

        expect(response.status).to eq(200)
        expect(body).to have_key('gender')
        expect(body['gender']).to be_nil
      end
    end

    it 'returns the goal of the contract: seek-help, give-help or both' do
      { 'ask_for_help' => 'seek-help', 'offer_help' => 'give-help', 'ask_and_offer_help' => 'both' }.each do |declared, expected|
        user.update!(goal: declared)
        call_route(key: 'assistant-secret-key', token: user.token)

        expect(body['goal']).to eq(expected)
      end
    end

    it 'returns the availabilities as texts, the day in English, in the order of the week' do
      user.update!(availability: { '7' => ['10:00-12:00'], '1' => ['09:00-12:00', '14:00-16:00'] })

      call_route(key: 'assistant-secret-key', token: user.token)

      expect(body['availabilities']).to eq(['monday 09:00-12:00', 'monday 14:00-16:00', 'sunday 10:00-12:00'])
    end

    it 'never returns the gender "other": the app has no such value' do
      user.update_columns(options: user.options.to_h.merge('gender' => 'other'))

      call_route(key: 'assistant-secret-key', token: user.token)

      expect(body['gender']).to be_nil
    end

    it 'returns missing informations as missing, without error' do
      bare = create :public_user, token: 'bare-token', goal: nil, interests: [], availability: {}
      bare.update_columns(address_id: nil)

      call_route(key: 'assistant-secret-key', token: bare.token)

      expect(response.status).to eq(200)
      expect(body).to include('city' => nil, 'goal' => nil, 'interests' => [], 'availabilities' => [], 'gender' => nil)
    end

    it 'returns no qualification of the person: no situation, segment or targeting profile' do
      user.update_columns(targeting_profile: 'asks_for_help')

      call_route(key: 'assistant-secret-key', token: user.token)

      expect(body.keys).to match_array(%w[city distanceKm goal interests availabilities gender])
      expect(response.body).not_to include('asks_for_help')
    end

    it 'only concerns the user of the token' do
      other = create :public_user, token: 'other-token', goal: 'ask_for_help', travel_distance: 3, interests: [], availability: {}

      call_route(key: 'assistant-secret-key', token: other.token)

      expect(body).to include('goal' => 'seek-help', 'distanceKm' => 3)
    end
  end
end
