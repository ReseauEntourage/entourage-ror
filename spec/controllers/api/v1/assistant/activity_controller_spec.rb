require 'rails_helper'

describe Api::V1::Assistant::ActivityController, type: :controller do
  let(:user) { create :public_user, token: 'user-secret-token' }
  let(:other) { create :public_user, first_name: 'Sam', last_name: 'Durand' }
  let(:body) { JSON.parse(response.body) }

  def call_route(key:, token:, params: {})
    request.headers['X-API-KEY'] = key if key
    request.headers['Authorization'] = "Bearer #{token}" if token
    get :read, params: params
  end

  it_behaves_like 'an assistant read'

  it 'is routed to GET /api/v1/assistant/activity' do
    expect(get: '/api/v1/assistant/activity').to route_to('api/v1/assistant/activity#read')
  end

  describe 'the activity' do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('ASSISTANT_API_KEY').and_return('assistant-secret-key')
    end

    def read
      call_route(key: 'assistant-secret-key', token: user.token)
    end

    def outing_at(starts_at, attributes = {})
      create :outing, :outing_class, { user: other, title: 'Un café', metadata: { starts_at: starts_at, ends_at: starts_at + 1.hour } }.merge(attributes)
    end

    it 'returns exactly these sections, empty for a new user' do
      read

      expect(body).to eq(
        'upcomingOutings' => [], 'pastOutings' => [], 'groups' => [], 'helpRequests' => [],
        'helpOffers' => [], 'answeredHelp' => [], 'conversations' => []
      )
    end

    it 'returns the upcoming and the past outings of the user' do
      upcoming = outing_at(2.days.from_now)
      past = outing_at(2.days.from_now, title: 'Déjà passé')
      past.update_columns(metadata: past.metadata.to_h.merge('starts_at' => 3.days.ago.iso8601, 'ends_at' => (3.days.ago + 1.hour).iso8601))
      create :join_request, user: user, joinable: upcoming, status: :accepted, role: :participant
      create :join_request, user: user, joinable: past, status: :accepted, role: :participant, participate_at: 3.days.ago
      outing_at(4.days.from_now, title: 'Pas inscrit')

      read

      expect(body['upcomingOutings'].map { |o| o['title'] }).to eq(['Un café'])
      expect(body['upcomingOutings'].first).to include('id' => upcoming.uuid_v2, 'role' => 'participant', 'participated' => false)
      expect(body['upcomingOutings'].first.keys).to match_array(%w[id title startsAt endsAt role participated])
      expect(body['pastOutings'].map { |o| [o['title'], o['participated']] }).to eq([['Déjà passé', true]])
    end

    it 'does not return a cancelled registration' do
      outing = outing_at(2.days.from_now)
      create :join_request, user: user, joinable: outing, status: :cancelled, role: :participant

      read

      expect(body['upcomingOutings']).to eq([])
    end

    it 'returns the groups, the publications and the help answered' do
      group = create :neighborhood, name: 'Foot Paris 17è'
      create :join_request, user: user, joinable: group, status: :accepted, role: :member
      request_published = create :solicitation, user: user, title: 'Besoin de courses'
      offer_published = create :contribution, user: user, title: 'Je prête une perceuse'
      answered = create :contribution, user: other, title: 'Cours de cuisine'
      create :join_request, user: user, joinable: answered, status: :accepted, role: :member

      read

      expect(body['groups']).to eq([{ 'id' => group.uuid_v2, 'name' => 'Foot Paris 17è' }])
      expect(body['helpRequests'].map { |h| h['id'] }).to eq([request_published.uuid_v2])
      expect(body['helpRequests'].first.keys).to match_array(%w[id title status createdAt])
      expect(body['helpOffers'].map { |h| h['id'] }).to eq([offer_published.uuid_v2])
      expect(body['answeredHelp']).to eq([{ 'id' => answered.uuid_v2, 'type' => 'offer', 'title' => 'Cours de cuisine' }])
    end

    describe 'the discussions' do
      let!(:conversation) { create :conversation, user: user, participants: [user, other] }

      before { create :chat_message, messageable: conversation, user: user, content: 'Un message très privé' }

      it 'returns the fact that a discussion exists and with whom, never its content' do
        read

        expect(body['conversations'].size).to eq(1)
        expect(body['conversations'].first).to eq(
          'id' => conversation.uuid_v2, 'with' => { 'id' => other.uuid, 'displayName' => 'Sam D.' },
          'startedAt' => conversation.created_at.iso8601
        )
        expect(response.body).not_to include('très privé')
        expect(response.body).not_to include('content')
      end

      it 'does not return the discussions of other members' do
        stranger = create :public_user
        create :conversation, user: other, participants: [other, stranger]

        read

        expect(body['conversations'].size).to eq(1)
      end
    end

    it 'bounds the lists to the latest items' do
      (Api::V1::Assistant::ActivityController.name && Assistant::Presenters::Activity::LIMIT + 5).times do
        create :solicitation, user: user
      end

      read

      expect(body['helpRequests'].size).to eq(Assistant::Presenters::Activity::LIMIT)
    end

    it 'loads the lists in a number of SQL queries that does not grow with the data' do
      queries = lambda do
        @controller = described_class.new
        count = 0
        subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
          count += 1 unless payload[:name] == 'SCHEMA' || payload[:sql] =~ /\A(BEGIN|COMMIT|SAVEPOINT|RELEASE)/
        end
        read
        ActiveSupport::Notifications.unsubscribe(subscriber)
        count
      end

      populate = lambda do
        outing = outing_at(2.days.from_now)
        create :join_request, user: user, joinable: outing, status: :accepted, role: :participant
        group = create :neighborhood
        create :join_request, user: user, joinable: group, status: :accepted, role: :member
        create :solicitation, user: user
        answered = create :contribution, user: create(:public_user)
        create :join_request, user: user, joinable: answered, status: :accepted, role: :member
        friend = create :public_user
        create :conversation, user: user, participants: [user, friend]
      end

      populate.call
      queries.call # warms the caches
      few = queries.call
      4.times { populate.call }
      many = queries.call

      expect(many).to eq(few)
    end
  end
end
