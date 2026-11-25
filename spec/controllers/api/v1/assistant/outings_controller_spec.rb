require 'rails_helper'

describe Api::V1::Assistant::OutingsController, type: :controller do
  let(:user) { create :public_user, token: 'user-secret-token' }
  let(:organizer) { create :public_user, first_name: 'Léa', last_name: 'Bernard' }
  let(:starts_at) { 3.days.from_now.change(hour: 14) }

  # not a `let`: several requests are made in some examples
  def body
    JSON.parse(response.body)
  end

  def create_outing(attributes = {})
    metadata = { starts_at: starts_at, ends_at: starts_at + 2.hours, place_name: 'Café des Lilas', display_address: '12 rue des Lilas, Paris' }
    create :outing, :outing_class, { user: organizer, title: 'Café partagé', description: 'Un café, puis une balade', metadata: metadata }.deep_merge(attributes)
  end

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('ASSISTANT_API_KEY').and_return('assistant-secret-key')
  end

  def search(params = {})
    @controller = described_class.new # a controller keeps what it memoized from a previous request
    request.headers['X-API-KEY'] = 'assistant-secret-key'
    request.headers['Authorization'] = "Bearer #{user.token}"
    get :search, params: params
  end

  def read_sheet(id)
    @controller = described_class.new
    request.headers['X-API-KEY'] = 'assistant-secret-key'
    request.headers['Authorization'] = "Bearer #{user.token}"
    get :read, params: { id: id }
  end

  it 'is routed under /api/v1/assistant/outings' do
    expect(get: '/api/v1/assistant/outings').to route_to('api/v1/assistant/outings#search')
    expect(get: '/api/v1/assistant/outings/abc').to route_to('api/v1/assistant/outings#read', id: 'abc')
  end

  describe 'search' do
    # Without an address nor a city, the Finder of the app does not filter on the place.
    before { create :address, user: user, city: 'Paris', latitude: 48.8566, longitude: 2.3522 }

    def call_route(key:, token:, params: {})
      @controller = described_class.new
      request.headers['X-API-KEY'] = key if key
      request.headers['Authorization'] = "Bearer #{token}" if token
      get :search, params: params
    end

    it_behaves_like 'an assistant read'

    it 'returns the outings close to the user, as briefs' do
      outing = create_outing
      create_outing(latitude: 43.3, longitude: 5.4, title: 'Trop loin')

      search

      expect(body['outings'].size).to eq(1)
      expect(body['outings'].first).to eq(
        'id' => outing.uuid_v2, 'title' => 'Café partagé', 'startsAt' => outing.starts_at.to_time.iso8601,
        'place' => outing.display_address, 'participantsCount' => 1, 'placeLimit' => nil,
        'reservedFemale' => false, 'format' => 'in_person'
      )
    end

    it 'counts the registered people and returns the place limit, so that the assistant can deduce the size' do
      outing = create_outing(metadata: { place_limit: 8 })
      create :join_request, user: user, joinable: outing, status: :accepted, role: :participant
      create :join_request, user: create(:public_user), joinable: outing, status: :cancelled

      search

      expect(body['outings'].first).to include('participantsCount' => 2, 'placeLimit' => 8)
    end

    it 'never returns an outing reserved to women unless the assistant asks for them' do
      create_outing(title: 'Pour tous')
      create_outing(title: 'Entre femmes', metadata: { reserved_female: true })

      search
      expect(body['outings'].map { |o| o['title'] }).to eq(['Pour tous'])

      search(reserved_female: 'true')
      expect(body['outings'].map { |o| o['title'] }).to eq(['Entre femmes'])
      expect(body['outings'].first['reservedFemale']).to eq(true)
    end

    it 'never returns a papotage without chatting, with or without a size' do
      create_outing(title: 'Sur place')
      create_outing(title: 'Papotage solidaire', online: true)
      create_outing(title: 'Atelier en ligne', online: true)

      search
      expect(body['outings'].map { |o| o['title'] }).to match_array(['Sur place', 'Atelier en ligne'])

      search(size: 'small-group')
      expect(body['outings'].map { |o| o['title'] }).to match_array(['Sur place', 'Atelier en ligne'])

      search(chatting: 'false')
      expect(body['outings'].map { |o| o['title'] }).to match_array(['Sur place', 'Atelier en ligne'])
    end

    it 'returns only the papotages when chatting is asked, with an online format and no place' do
      create_outing(title: 'Sur place')
      create_outing(title: 'Papotage solidaire', online: true)
      create_outing(title: 'Atelier en ligne', online: true)

      search(chatting: 'true')

      expect(body['outings'].map { |o| o['title'] }).to eq(['Papotage solidaire'])
      expect(body['outings'].first).to include('format' => 'online', 'place' => nil)
    end

    it 'filters on the days of the week of the start, 1 being Monday, and ignores what is not a day' do
      monday = Time.zone.now.next_occurring(:monday).change(hour: 14)
      tuesday = monday + 1.day
      create_outing(title: 'Le lundi', metadata: { starts_at: monday, ends_at: monday + 1.hour })
      create_outing(title: 'Le mardi', metadata: { starts_at: tuesday, ends_at: tuesday + 1.hour })

      search(days: '1')
      expect(body['outings'].map { |o| o['title'] }).to eq(['Le lundi'])

      search(days: '2, 9, lundi')
      expect(body['outings'].map { |o| o['title'] }).to eq(['Le mardi'])

      search(days: '1,2')
      expect(body['outings'].size).to eq(2)

      search(days: 'lundi')
      expect(body['outings'].size).to eq(2)
    end

    it 'filters on the interest' do
      create_outing(title: 'Atelier couture', interests: ['jeux'])
      create_outing(title: 'Match de foot', interests: ['sport'])

      search(interest: 'sport')

      expect(body['outings'].map { |o| o['title'] }).to eq(['Match de foot'])
    end

    it 'does not return the outings that the app hides from this user' do
      create_outing(title: 'Pour ceux qui offrent', exclusive_to: 'offer_help')
      user.update_columns(goal: 'ask_for_help')

      search

      expect(body['outings']).to eq([])
    end

    it 'does not return a closed outing' do
      create_outing(title: 'Fermé', status: 'closed')

      search

      expect(body['outings']).to eq([])
    end

    it 'returns 10 outings at most, and 30 when the assistant asks for a size to choose from' do
      12.times { create_outing }

      search
      expect(body['outings'].size).to eq(10)

      search(size: 'small-group')
      expect(body['outings'].size).to eq(12)
    end

    it 'does not apply the size itself: the assistant filters on it' do
      create_outing(metadata: { place_limit: 2 })
      create_outing(metadata: { place_limit: 40 })

      search(size: 'pair')

      expect(body['outings'].size).to eq(2)
    end

    it 'bounds the number of SQL queries' do
      count_queries = lambda do
        queries = 0
        subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
          queries += 1 unless payload[:name] == 'SCHEMA' || payload[:sql] =~ /\A(BEGIN|COMMIT|SAVEPOINT|RELEASE)/
        end
        search
        ActiveSupport::Notifications.unsubscribe(subscriber)
        queries
      end

      2.times { create_outing }
      count_queries.call # warms the caches (schema, tags)
      few = count_queries.call
      6.times { create_outing }
      many = count_queries.call

      expect(many).to eq(few)
    end

    describe 'the city' do
      before do
        create_outing(title: 'À Paris')
        create_outing(title: 'À Lyon', latitude: 45.764, longitude: 4.8357)
        allow(Geocoder).to receive(:search)
      end

      it 'does not geocode the city of the profile: the text does not leave Local' do
        search(city: 'paris')

        expect(Geocoder).not_to have_received(:search)
        expect(body['outings'].map { |o| o['title'] }).to eq(['À Paris'])
      end

      it 'does not geocode without a city' do
        search

        expect(Geocoder).not_to have_received(:search)
      end

      it 'geocodes another city with the geocoder of the app, and searches around it' do
        allow(Geocoder).to receive(:search).with('Lyon').and_return([double(latitude: 45.764, longitude: 4.8357)])

        search(city: 'Lyon')

        expect(body['outings'].map { |o| o['title'] }).to eq(['À Lyon'])
      end

      it 'answers 404 PLACE_NOT_FOUND for a city that the geocoder does not know' do
        allow(Geocoder).to receive(:search).with('Atlantis').and_return([])

        search(city: 'Atlantis')

        expect([response.status, body.dig('error', 'code')]).to eq([404, 'PLACE_NOT_FOUND'])
      end
    end
  end

  describe 'sheet' do
    it_behaves_like 'an assistant read' do
      def call_route(key:, token:, params: {})
        @controller = described_class.new
        request.headers['X-API-KEY'] = key if key
        request.headers['Authorization'] = "Bearer #{token}" if token
        get :read, params: { id: outing.uuid_v2 }.merge(params)
      end

      let!(:outing) { create_outing }
    end

    it 'returns the flat sheet of an outing, with its stable identifier and its type of meeting' do
      outing = create_outing(metadata: { place_limit: 12 })
      outing.update!(sf_category_list: ['atelier_femmes'])

      read_sheet(outing.uuid_v2)

      expect(response.status).to eq(200)
      expect(body).to eq(
        'id' => outing.uuid_v2, 'title' => 'Café partagé', 'description' => 'Un café, puis une balade',
        'startsAt' => outing.starts_at.to_time.iso8601, 'endsAt' => outing.ends_at.to_time.iso8601, 'durationMinutes' => 120,
        'place' => outing.display_address, 'organizerName' => 'Léa B.', 'participantsCount' => 1, 'placeLimit' => 12,
        'format' => 'in_person', 'reservedFemale' => false, 'subjectId' => outing.uuid_v2, 'meetingType' => 'atelier_femmes'
      )
    end

    it 'returns the description as it is, without inventing a program' do
      outing = create_outing(description: 'Venez nombreux')

      read_sheet(outing.uuid_v2)

      expect(body['description']).to eq('Venez nombreux')
      expect(response.body).not_to match(/charte|programme|déroulé/i)
    end

    it 'returns a missing information as missing, never completed' do
      outing = create_outing
      outing.update_columns(description: nil, metadata: outing.metadata.to_h.with_indifferent_access.except('place_name', 'display_address', 'street_address', 'ends_at'))

      read_sheet(outing.uuid_v2)

      expect(body).to include('description' => nil, 'durationMinutes' => nil, 'place' => nil, 'endsAt' => nil)
    end

    it 'finds the outing by its numeric id too' do
      outing = create_outing

      read_sheet(outing.id)

      expect(body['id']).to eq(outing.uuid_v2)
    end

    it 'does not show an outing that the app hides from this user, nor an unknown one' do
      hidden = create_outing(exclusive_to: 'offer_help')
      user.update_columns(goal: 'ask_for_help')

      expect { read_sheet(hidden.uuid_v2) }.to raise_error(ActiveRecord::RecordNotFound)
      expect { read_sheet('unknown') }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
