require 'rails_helper'

# Requests and offers of help close to a place, and the categories of help of the app.
describe Api::V1::Assistant::HelpRequestsController, type: :controller do
  let(:user) { create :public_user, token: 'user-secret-token' }
  let(:author) { create :public_user, first_name: 'Sam', last_name: 'Durand' }
  let(:body) { JSON.parse(response.body) }

  def call_route(key:, token:, params: {})
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

    def search(params = {})
      call_route(key: 'assistant-secret-key', token: user.token, params: { latitude: 48.85, longitude: 2.35 }.merge(params))
    end

    it 'returns the requests close to the place, with exactly these fields' do
      near = create :solicitation, user: author, title: 'Besoin de courses', description: 'Une fois par semaine',
                                   latitude: 48.851, longitude: 2.351, section_list: ['services']
      create :solicitation, user: author, title: 'Trop loin', latitude: 43.3, longitude: 5.4

      search(distance: 10)

      expect(body['helpRequests'].size).to eq(1)
      expect(body['helpRequests'].first).to eq(
        'id' => near.uuid_v2, 'type' => 'request', 'title' => 'Besoin de courses', 'description' => 'Une fois par semaine',
        'category' => 'services', 'createdAt' => near.created_at.iso8601,
        'author' => { 'id' => author.uuid, 'displayName' => 'Sam D.' }
      )
      expect(response.body).not_to include(author.phone)
    end

    it 'filters on the categories' do
      create :solicitation, user: author, title: 'Courses', latitude: 48.851, longitude: 2.351, section_list: ['services']
      create :solicitation, user: author, title: 'Café', latitude: 48.851, longitude: 2.351, section_list: ['social']

      search(section_list: 'social')

      expect(body['helpRequests'].map { |item| item['title'] }).to eq(['Café'])
    end

    it 'does not return a closed request' do
      create :solicitation, user: author, latitude: 48.851, longitude: 2.351, status: 'closed'

      search

      expect(body['helpRequests']).to eq([])
    end

    it 'bounds the number of results' do
      3.times { create :solicitation, user: author, latitude: 48.851, longitude: 2.351 }

      search(limit: 2)

      expect(body['helpRequests'].size).to eq(2)
    end
  end
end

describe Api::V1::Assistant::HelpOffersController, type: :controller do
  let(:user) { create :public_user, token: 'user-secret-token' }
  let(:author) { create :public_user, first_name: 'Sam', last_name: 'Durand' }
  let(:body) { JSON.parse(response.body) }

  def call_route(key:, token:, params: {})
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

    call_route(key: 'assistant-secret-key', token: user.token, params: { latitude: 48.85, longitude: 2.35 })

    expect(body.keys).to eq(['helpOffers'])
    expect(body['helpOffers'].map { |item| [item['id'], item['type'], item['title']] }).to eq([[offer.uuid_v2, 'offer', 'Je prête ma perceuse']])
  end
end

describe Api::V1::Assistant::HelpCategoriesController, type: :controller do
  let(:user) { create :public_user, token: 'user-secret-token' }

  def call_route(key:, token:, params: {})
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
