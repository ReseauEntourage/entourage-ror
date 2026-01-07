require 'rails_helper'
include CommunityHelper

describe Api::V1::HomeController do

  let(:user) { FactoryBot.create(:offer_help_user) }
  let(:pro_user) { FactoryBot.create(:pro_user) }

  describe 'GET index' do
    context 'not signed in' do
      before { get :index }
      it { expect(response.status).to eq(401) }
    end

    context 'signed in' do
      # entourages
      let!(:entourage) { FactoryBot.create(:entourage, :joined, user: user, status: 'open', latitude: 48.85436, longitude: 2.270340) }
      let!(:entourage_closed) { FactoryBot.create(:entourage, :joined, user: user, status: 'closed', latitude: 48.85436, longitude: 2.270340) }
      # outings
      let!(:outing) { FactoryBot.create(:outing) }
      # announcements
      let!(:announcement) { FactoryBot.create(:announcement, user_goals: [:offer_help], areas: [:sans_zone]) }
      let!(:announcement_ask) { FactoryBot.create(:announcement, user_goals: [:ask_for_help], areas: [:sans_zone], id: 2) }

      subject { JSON.parse(response.body) }

      it 'renders json keys' do
        get :index, params: { token: user.token }

        expect(subject).to have_key('metadata')
        expect(subject).to have_key('headlines')
        expect(subject).to have_key('outings')
        expect(subject).to have_key('entourage_contributions')
        expect(subject).to have_key('entourage_ask_for_helps')
      end

      it 'renders entourage_ask_for_helps' do
        entourage.update_attribute(:entourage_type, :ask_for_help)

        get :index, params: { token: user.token, latitude: 48.854367553784954, longitude: 2.270340589096274 }

        expect(subject['entourage_ask_for_helps'].count).to eq(1)
        expect(subject['entourage_ask_for_helps']).to eq(
          [{
            'id' => entourage.id,
            'uuid'=>entourage.uuid_v2,
            'status'=>'open',
            'title'=>'Foobar',
            'group_type'=>'action',
            'public'=>false,
            'metadata'=>{'city'=>'', 'display_address'=>''},
            'entourage_type'=>'ask_for_help',
            'display_category'=>'social',
            'postal_code'=>nil,
            'number_of_people'=>1,
            'author'=>{
              'id'=>entourage.user.id,
              'display_name'=>'John D.',
              'avatar_url'=>nil,
              'partner'=>nil,
              'partner_role_title' => nil,
            },
            'location'=>{
              'latitude'=>48.85436,
              'longitude'=>2.270340
            },
            'join_status'=>'accepted',
            'number_of_unread_messages'=>0,
            'created_at'=> entourage.created_at.iso8601(3),
            'updated_at'=> entourage.updated_at.iso8601(3),
            'description' => nil,
            'share_url' => "#{ENV['MOBILE_HOST']}/app/solicitations/#{entourage.uuid_v2}",
            'image_url'=>nil,
            'online'=>false,
            'event_url'=>nil,
            'display_report_prompt' => false
          }]
        )
      end

      it 'renders outings, no coordinate' do
        get :index, params: { token: user.token }

        expect(subject['outings'].count).to eq(0)
      end

      it 'renders outings, with coordinate' do
        get :index, params: { token: user.token, latitude: 48.854367553784954, longitude: 2.270340589096274 }

        expect(subject['outings'].count).to eq(1)
      end
    end
  end

  describe 'GET metadata' do
    let!(:reaction) { create(:reaction) }
    let!(:category) { create(:category, name: :alimentaire) }
    let(:result) { JSON.parse(response.body) }

    before { get :metadata, params: { token: user.token } }

    it { expect(response.status).to eq(200) }
    it { expect(result).to have_key('tags') }
    it { expect(result['tags']).to be_a(Hash) }
    # sections
    it { expect(result['tags']).to have_key('sections') }
    it { expect(result['tags']['sections']).to be_a(Array) }
    it { expect(result['tags']['sections'][0]).to eq({
      'id' => 'social',
      'name' => 'Temps de partage',
      'subname' => 'café, activité...'
    }) }
    # interests
    it { expect(result['tags']).to have_key('interests') }
    it { expect(result['tags']['interests']).to be_a(Array) }
    it { expect(result['tags']['interests'][0]).to eq({
      'id' => 'activites',
      'name' => 'Activités manuelles'
    }) }
    # involvements
    it { expect(result['tags']).to have_key('involvements') }
    it { expect(result['tags']['involvements']).to be_a(Array) }
    it { expect(result['tags']['involvements'][0]).to eq({
      'id' => 'resources',
      'name' => 'Apprendre avec des contenus pédagogiques'
    }) }
    # concerns
    it { expect(result['tags']).to have_key('concerns') }
    it { expect(result['tags']['concerns']).to be_a(Array) }
    it { expect(result['tags']['concerns'][0]).to eq({
      'id' => 'sharing_time',
      'name' => 'Temps de partage'
    }) }
    # signals
    it { expect(result['tags']).to have_key('signals') }
    it { expect(result['tags']['signals']).to be_a(Array) }
    it { expect(result['tags']['signals'][0]).to eq({
      'id' => 'spam',
      'name' => 'Spam'
    }) }
    # reactions
    it { expect(result).to have_key('reactions') }
    it { expect(result['reactions']).to eq([
      {
        'id' => reaction.id,
        'name' => reaction.name,
        'key' => reaction.key,
        'image_url' => reaction.image_url }
    ]) }
    # poi_categories
    it { expect(result).to have_key('poi_categories') }
    it { expect(result['poi_categories']).to eq([
      {
        'id' => category.id,
        'name' => category.name
      }
    ]) }
  end

  describe 'GET summary' do
    subject { JSON.parse(response.body) }

    before { User.any_instance.stub(:latitude) { 40 } }
    before { User.any_instance.stub(:longitude) { 2 } }

    context 'not signed in' do
      before { get :summary }
      it { expect(response.status).to eq(401) }
    end

    context 'signed in' do
      let!(:recommandation) { FactoryBot.create(:recommandation_contribution) }
      let!(:user_recommandation) { FactoryBot.create(:user_recommandation, user: user, recommandation: recommandation, fragment: recommandation.fragment) }

      let(:request) { get :summary, params: { token: user.token } }

      context 'renders default fields' do
        before { request }

        it { expect(subject).to eq({
          'user' => {
            'id' => user.id,
            'lang' => 'fr',
            'display_name' => 'John D.',
            'avatar_url' => nil,
            'preference' => 'solicitation',
            'association' => false,
            'community_roles' => [],
            'meetings_count' => 0,
            'chat_messages_count' => 0,
            'outing_participations_count' => 0,
            'neighborhood_participations_count' => 0,
            'recommandations' => [],
            'congratulations' => [],
            'unclosed_action' => nil,
            'moderator' => {},
            'signable_permission' => false
          }
        }) }
      end

      context "with signable_permission" do
        let(:user) { create(:offer_help_user, targeting_profile: :ambassador) }

        before { request }

        it { expect(subject["user"]["signable_permission"]).to eq(true) }
      end

      let(:entourage) { FactoryBot.create(:entourage) }
      let(:outing) { FactoryBot.create(:outing) }
      let(:conversation) { FactoryBot.create(:conversation) }
      let(:neighborhood) { FactoryBot.create(:neighborhood) }

      context 'renders meetings_count' do
        before { request }

        it { expect(subject['user']['meetings_count']).to eq(0) }
      end

      context 'renders outing_participations_count' do
        let!(:join_request) { FactoryBot.create(:join_request, joinable: outing, user: user, status: :accepted) }
        let!(:join_request_pro) { FactoryBot.create(:join_request, joinable: outing, user: pro_user, status: :accepted) }

        before { request }

        it { expect(subject['user']['outing_participations_count']).to eq(1) }
      end

      context 'renders neighborhood_participations_count' do
        let!(:join_request) { FactoryBot.create(:join_request, joinable: neighborhood, user: user, status: :accepted) }
        let!(:join_request_pro) { FactoryBot.create(:join_request, joinable: neighborhood, user: pro_user, status: :accepted) }

        before { request }

        it { expect(subject['user']['neighborhood_participations_count']).to eq(1) }
      end

      context 'renders unclosed_action' do
        let(:creation_time) { V1::Users::SummarySerializer::UNCLOSED_ACTION_ALERT }

        context 'old action' do
          let!(:entourage) { FactoryBot.create(:entourage, user: user, created_at: (creation_time + 1.day).ago) }

          before { request }

          it { expect(subject['user']['unclosed_action']).to be_a(Hash) }
          it { expect(subject['user']['unclosed_action']['id']).to eq(entourage.id) }
        end

        context 'recent action' do
          let!(:entourage) { FactoryBot.create(:entourage, user: user, created_at: (creation_time - 1.day).ago) }

          before { request }

          it { expect(subject['user']['unclosed_action']).to be_nil }
        end

        context 'order by created_at' do
          let!(:entourage_1) { FactoryBot.create(:entourage, user: user, created_at: (creation_time + 1.day).ago) }
          let!(:entourage_2) { FactoryBot.create(:entourage, user: user, created_at: (creation_time + 2.day).ago) }

          before { request }

          it { expect(subject['user']['unclosed_action']).to be_a(Hash) }
          it { expect(subject['user']['unclosed_action']['id']).to eq(entourage_2.id) }
        end
      end
    end
  end
end
