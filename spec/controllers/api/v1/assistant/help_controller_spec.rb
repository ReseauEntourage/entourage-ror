require 'rails_helper'

# Requests and offers of help close to a place, and the categories of help of the app.
describe Api::V1::Assistant::HelpRequestsController, type: :controller do
  let(:user) { create :public_user, token: 'user-secret-token' }
  let(:author) { create :public_user, first_name: 'Sam', last_name: 'Durand' }
  # not a `let`: several requests are made in some examples
  def body
    JSON.parse(response.body)
  end

  def call_route(key:, token:, params: {})
    @controller = described_class.new
    request.headers['X-API-KEY'] = key if key
    request.headers['Authorization'] = "Bearer #{token}" if token
    get :search, params: params
  end

  it_behaves_like 'an assistant read'

  it 'is routed to GET /api/v1/assistant/help_requests and help_offers' do
    expect(get: '/api/v1/assistant/help_requests').to route_to('api/v1/assistant/help_requests#search')
    expect(get: '/api/v1/assistant/help_offers').to route_to('api/v1/assistant/help_offers#search')
  end

  describe 'search' do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('ASSISTANT_API_KEY').and_return('assistant-secret-key')
    end

    before { create :address, user: user, city: 'Paris', latitude: 48.85, longitude: 2.35 }

    def search(params = {})
      call_route(key: 'assistant-secret-key', token: user.token, params: params)
    end

    it 'returns the requests close to the user, with their title and category only: no text, no author' do
      near = create :solicitation, user: author, title: 'Besoin de courses', description: 'Une fois par semaine',
                                   latitude: 48.851, longitude: 2.351, section_list: ['services']
      create :solicitation, user: author, title: 'Trop loin', latitude: 43.3, longitude: 5.4

      search

      expect(body['items']).to eq([{ 'id' => near.uuid_v2, 'title' => 'Besoin de courses', 'category' => 'services' }])
      expect(response.body).not_to include('Une fois par semaine')
      expect(response.body).not_to include(author.uuid)
      expect(response.body).not_to include('Sam')
      expect(response.body).not_to include(author.phone)
    end

    it 'filters on the categories' do
      create :solicitation, user: author, title: 'Courses', latitude: 48.851, longitude: 2.351, section_list: ['services']
      create :solicitation, user: author, title: 'Café', latitude: 48.851, longitude: 2.351, section_list: ['social']

      search(category: 'social')

      expect(body['items'].map { |item| item['title'] }).to eq(['Café'])
    end

    it 'does not return a closed request' do
      create :solicitation, user: author, latitude: 48.851, longitude: 2.351, status: 'closed'

      search

      expect(body['items']).to eq([])
    end

    it 'bounds the number of results to 10' do
      12.times { create :solicitation, user: author, latitude: 48.851, longitude: 2.351 }

      search

      expect(body['items'].size).to eq(10)
    end

    it 'geocodes a city other than the one of the profile, and not the city of the profile' do
      allow(Geocoder).to receive(:search)
      create :solicitation, user: author, title: 'À Lyon', latitude: 45.764, longitude: 4.8357
      allow(Geocoder).to receive(:search).with('Lyon').and_return([double(latitude: 45.764, longitude: 4.8357)])

      search(city: 'Lyon')
      expect(body['items'].map { |item| item['title'] }).to eq(['À Lyon'])

      search(city: 'Paris')
      expect(Geocoder).not_to have_received(:search).with('Paris')
    end

    it 'answers 404 PLACE_NOT_FOUND for an unknown city' do
      allow(Geocoder).to receive(:search).with('Atlantis').and_return([])

      search(city: 'Atlantis')

      expect([response.status, body.dig('error', 'code')]).to eq([404, 'PLACE_NOT_FOUND'])
    end
  end
end

describe Api::V1::Assistant::HelpOffersController, type: :controller do
  let(:user) { create :public_user, token: 'user-secret-token' }
  let(:author) { create :public_user, first_name: 'Sam', last_name: 'Durand' }
  # not a `let`: several requests are made in some examples
  def body
    JSON.parse(response.body)
  end

  def call_route(key:, token:, params: {})
    @controller = described_class.new
    request.headers['X-API-KEY'] = key if key
    request.headers['Authorization'] = "Bearer #{token}" if token
    get :search, params: params
  end

  it_behaves_like 'an assistant read'

  it 'returns the offers close to the place, not the requests' do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('ASSISTANT_API_KEY').and_return('assistant-secret-key')
    offer = create :contribution, user: author, title: 'Je prête ma perceuse', latitude: 48.851, longitude: 2.351, section_list: ['equipment']
    create :solicitation, user: author, title: 'Une demande', latitude: 48.851, longitude: 2.351

    create :address, user: user, city: 'Paris', latitude: 48.85, longitude: 2.35
    call_route(key: 'assistant-secret-key', token: user.token)

    expect(body.keys).to eq(['items'])
    expect(body['items']).to eq([{ 'id' => offer.uuid_v2, 'title' => 'Je prête ma perceuse', 'category' => 'equipment' }])
  end
end

describe Api::V1::Assistant::HelpCategoriesController, type: :controller do
  let(:user) { create :public_user, token: 'user-secret-token' }

  def call_route(key:, token:, params: {})
    @controller = described_class.new
    request.headers['X-API-KEY'] = key if key
    request.headers['Authorization'] = "Bearer #{token}" if token
    get :read, params: params
  end

  it_behaves_like 'an assistant read'

  it 'returns the categories of the app and no other' do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('ASSISTANT_API_KEY').and_return('assistant-secret-key')

    call_route(key: 'assistant-secret-key', token: user.token)

    categories = JSON.parse(response.body)['categories']
    expect(categories.map { |category| category['id'] }).to eq(Tag.section_list)
    expect(categories.first).to eq('id' => 'social', 'name' => Tag.sections[:social][:name])
  end
end
