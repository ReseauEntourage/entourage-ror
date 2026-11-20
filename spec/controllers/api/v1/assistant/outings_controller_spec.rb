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
    outing = create :outing, :outing_class, { user: organizer, title: 'Café partagé', description: 'Un café, puis une balade', metadata: metadata }.deep_merge(attributes)
    outing
  end

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('ASSISTANT_API_KEY').and_return('assistant-secret-key')
  end

  def search(params = {})
    call_route(key: 'assistant-secret-key', token: user.token, params: { latitude: 48.854, longitude: 2.27 }.merge(params))
  end

  describe 'the routes' do
    it 'are routed under /api/v1/assistant/outings' do
      expect(get: '/api/v1/assistant/outings').to route_to('api/v1/assistant/outings#search')
      expect(get: '/api/v1/assistant/outings/abc').to route_to('api/v1/assistant/outings#read', id: 'abc')
    end
  end

  describe 'search' do
    def call_route(key:, token:, params: {})
      @controller = described_class.new # a controller keeps what it memoized from a previous request
      request.headers['X-API-KEY'] = key if key
      request.headers['Authorization'] = "Bearer #{token}" if token
      get :search, params: params
    end

    it_behaves_like 'an assistant read'

    it 'returns the outings close to the place, with the sheet fields' do
      outing = create_outing
      create_outing(latitude: 43.3, longitude: 5.4, title: 'Trop loin')

      search(distance: 10)

      expect(body['outings'].size).to eq(1)
      expect(body['outings'].first).to eq(
        'id' => outing.uuid_v2, 'title' => 'Café partagé', 'description' => 'Un café, puis une balade',
        'startsAt' => outing.starts_at.to_time.iso8601, 'endsAt' => outing.ends_at.to_time.iso8601, 'durationMinutes' => 120,
        'format' => 'in_person', 'place' => { 'name' => 'Café des Lilas', 'address' => outing.display_address },
        'organizer' => { 'id' => organizer.uuid, 'displayName' => 'Léa B.' },
        'participantsCount' => 1, 'placeLimit' => nil, 'reservedFemale' => false,
        'measure' => { 'eventId' => outing.uuid_v2, 'meetingType' => 'event' }
      )
      expect(response.body).not_to include(organizer.phone)
    end

    it 'counts the registered people and returns the place limit' do
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

    it 'filters on the format and on the papotages' do
      create_outing(title: 'Sur place')
      create_outing(title: 'Papotage solidaire', online: true)
      create_outing(title: 'Atelier en ligne', online: true)

      search(meeting_format: 'online')
      expect(body['outings'].map { |o| o['title'] }).to match_array(['Papotage solidaire', 'Atelier en ligne'])

      search(category: 'papotages')
      expect(body['outings'].map { |o| o['title'] }).to eq(['Papotage solidaire'])
      expect(body['outings'].first['measure']['meetingType']).to eq('papotage')
      expect(body['outings'].first['place']).to be_nil
    end

    it 'filters on the number of days' do
      create_outing(title: 'Bientôt')
      create_outing(title: 'Plus tard', metadata: { starts_at: 20.days.from_now, ends_at: 20.days.from_now + 1.hour })

      search(within_days: 7)

      expect(body['outings'].map { |o| o['title'] }).to eq(['Bientôt'])
    end

    it 'filters on the words and the interests' do
      create_outing(title: 'Atelier couture', interests: ['jeux'])
      create_outing(title: 'Match de foot', interests: ['sport'])

      search(q: 'couture')
      expect(body['outings'].map { |o| o['title'] }).to eq(['Atelier couture'])

      search(interests: ['sport'])
      expect(body['outings'].map { |o| o['title'] }).to eq(['Match de foot'])
    end

    it 'does not return the outings that the app hides from this user' do
      create_outing(title: 'Pour ceux qui offrent', exclusive_to: 'offer_help')
      user.update_columns(goal: 'ask_for_help')

      search

      expect(body['outings']).to eq([])
    end

    it 'does not return a past or cancelled outing' do
      create_outing(title: 'Annulé', status: 'closed')

      search

      expect(body['outings']).to eq([])
    end

    it 'bounds the number of results and the number of SQL queries' do
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
      search(limit: 3)
      expect(body['outings'].size).to eq(3)
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

    def read_sheet(id)
      @controller = described_class.new
      request.headers['X-API-KEY'] = 'assistant-secret-key'
      request.headers['Authorization'] = "Bearer #{user.token}"
      get :read, params: { id: id }
    end

    it 'returns the sheet of an outing, with the stable identifiers of the measure subject' do
      outing = create_outing
      outing.update!(sf_category_list: ['atelier_femmes'])

      read_sheet(outing.uuid_v2)

      expect(response.status).to eq(200)
      expect(body['id']).to eq(outing.uuid_v2)
      expect(body['measure']).to eq('eventId' => outing.uuid_v2, 'meetingType' => 'atelier_femmes')
      expect(body.keys).to match_array(%w[id title description startsAt endsAt durationMinutes format place organizer participantsCount placeLimit reservedFemale measure])
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
