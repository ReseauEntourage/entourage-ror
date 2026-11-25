require 'rails_helper'

describe Api::V1::NextStepsController, type: :controller do
  let(:user) { create(:public_user, travel_distance: 10, goal: 'offer_help') }
  let(:nearby) { { latitude: 48.86, longitude: 2.3522 } }
  let(:result) { JSON.parse(response.body) }

  def ready! user, segment: 'Contributeur', sub_segment: nil
    address = create(:address, user: user, latitude: 48.8566, longitude: 2.3522, postal_code: '75001')
    user.update_columns(address_id: address.id, first_sign_in_at: 40.days.ago, created_at: 40.days.ago)
    create(:user_segment, user: user, engagement_segment: segment, engagement_sub_segment: sub_segment)
    user.reload
  end

  describe 'GET current' do
    it 'refuses an unauthenticated client' do
      get :current

      expect(response.status).to eq(401)
    end

    it 'returns no hero during the welcome journey' do
      get :current, params: { token: user.token }

      expect(response.status).to eq(200)
      expect(result).to eq('next_step' => nil)
    end

    context 'once the welcome journey is over' do
      before { ready!(user) }

      let!(:group) { create(:neighborhood, interest_list: ['sport'], **nearby) }

      it 'returns the hero with its target, its reasons and its expiry' do
        user.update!(interest_list: ['sport'])

        get :current, params: { token: user.token }

        hero = result['next_step']
        expect(hero).to include('kind' => 'neighborhood', 'mode' => 'segment', 'placement' => 'hero')
        expect(hero['id']).to eq(NextStep.active.find_by(user_id: user.id).id)
        expect(hero['target']['id']).to eq(group.id)
        expect(hero['reasons'].map { |reason| reason['code'] }).to eq(['local_group', 'shared_interests'])
        expect(hero['reasons'].first['text']).to eq("Un groupe de personnes près de chez vous, pour échanger et s'entraider.")
        expect(hero['expires_at']).to be_present
      end

      it 'returns the same hero at the next call' do
        get :current, params: { token: user.token }
        first_id = result['next_step']['id']

        get :current, params: { token: user.token }

        expect(JSON.parse(response.body)['next_step']['id']).to eq(first_id)
      end
    end
  end

  describe 'the target of a lieu solidaire' do
    before { ready!(user) }

    it 'has its id and the format of GET /pois/:id' do
      create(:category, id: 42, name: 'Douches')
      create(:solicitation, user: user, section_list: ['hygiene'], created_at: 5.days.ago, **nearby)
      showers = create(:poi, category_id: 42, **nearby)

      get :current, params: { token: user.token }

      target = result['next_step']['target']
      expect(result['next_step']['kind']).to eq('poi')
      expect(target['id']).to eq(showers.id)
      expect(target.except('id').keys).to eq(V1::PoiSerializer.new(showers, scope: { version: :v2 }).as_json.keys.map(&:to_s))
    end
  end

  describe 'GET others' do
    before { ready!(user) }

    it 'returns up to 3 suggestions, without the ignored ones' do
      ignored = create(:neighborhood, **nearby)
      create(:next_step, user: user, kind: 'neighborhood', target_type: 'Neighborhood', target_id: ignored.id,
        status: 'ignored', first_displayed_at: 11.days.ago, ignored_at: 10.days.ago, expires_at: 8.days.ago)
      create_list(:outing, 2, **nearby)
      create(:neighborhood, **nearby)

      get :others, params: { token: user.token }

      others = result['next_steps']
      expect(others.size).to be <= 3
      expect(others.map { |other| other['placement'] }.uniq).to eq(['others'])
      expect(others.map { |other| other['kind'] }).to eq(['outing', 'neighborhood', 'smalltalk'])
      expect(others.map { |other| other.dig('target', 'id') }).not_to include(ignored.id)
    end

    # recette of 23/11/2026: the apps fetch both routes together, in any order
    it 'leaves out the hero, even when it is asked before the hero' do
      create_list(:outing, 2, **nearby)

      get :others, params: { token: user.token }
      others = JSON.parse(response.body)['next_steps']

      get :current, params: { token: user.token }
      hero = JSON.parse(response.body)['next_step']

      expect(hero).to include('kind' => 'outing', 'id' => NextStep.active.find_by(user_id: user.id).id)
      expect(others.map { |other| [other['kind'], other.dig('target', 'id')] }).not_to include(['outing', hero.dig('target', 'id')])
    end
  end

  describe 'POST ignore' do
    before { ready!(user) }

    let!(:groups) { create_list(:neighborhood, 2, **nearby) }

    it 'replaces the hero' do
      hero = NextSteps::Current.new(user).call

      post :ignore, params: { token: user.token, id: hero.id }

      expect(hero.reload.status).to eq('ignored')
      expect(result['next_step']['id']).not_to eq(hero.id)
    end

    it "answers not found for another user's hero, and changes nothing" do
      other = create(:public_user)
      hero = create(:next_step, user: other)

      post :ignore, params: { token: user.token, id: hero.id }

      expect(response.status).to eq(404)
      expect(hero.reload.status).to eq('active')
    end
  end

  describe 'POST interactions' do
    before { ready!(user) }

    let!(:group) { create(:neighborhood, **nearby) }
    let(:hero) { NextSteps::Current.new(user).call }

    it 'records an interaction on the hero' do
      post :interactions, params: { token: user.token, interaction: { placement: 'hero', kind: 'why_opened', next_step_id: hero.id } }

      expect(response.status).to eq(204)
      expect(NextStepInteraction.last).to have_attributes(user_id: user.id, next_step_id: hero.id, kind: 'why_opened', item_kind: 'neighborhood', target_id: group.id)
    end

    it 'records an interaction on one of the others' do
      post :interactions, params: { token: user.token, interaction: { placement: 'others', kind: 'tapped', item_kind: 'outing', target_id: 42 } }

      expect(response.status).to eq(204)
      expect(NextStepInteraction.last).to have_attributes(next_step_id: nil, item_kind: 'outing', target_type: 'Outing', target_id: 42)
    end

    it "answers not found for another user's hero" do
      other_hero = create(:next_step, user: create(:public_user))

      post :interactions, params: { token: user.token, interaction: { placement: 'hero', kind: 'displayed', next_step_id: other_hero.id } }

      expect(response.status).to eq(404)
      expect(NextStepInteraction.count).to eq(0)
    end

    it 'refuses an unknown interaction' do
      post :interactions, params: { token: user.token, interaction: { placement: 'hero', kind: 'liked', next_step_id: hero.id } }

      expect(response.status).to eq(400)
    end
  end

  describe 'why this suggestion (6.3)' do
    it 'uses the gentle variant for a person in precarity, without mentioning the profile' do
      precarity = create(:public_user, travel_distance: 10, goal: 'ask_for_help')
      ready!(precarity, segment: 'Silencieux', sub_segment: 'À activer')
      offer = create(:contribution, title: 'je donne un duvet', **nearby)

      get :current, params: { token: precarity.token }

      hero = result['next_step']
      expect(hero['target']['id']).to eq(offer.id)
      expect(hero['target']['title']).to eq(Entourage.find(offer.id).title) # as stored, never reworded
      expect(hero['reasons'].first['text']).to eq("Quelqu'un près de chez vous propose son aide. Vous pouvez lui écrire simplement.")
      expect(hero['reasons'].map { |reason| reason['text'] }.join(' ')).not_to match(/précarité|isolé|riverain|silencieux|à activer|segment/i)
    end

    it 'reads the volunteers webinar link of the become-volunteer gesture from NEXT_STEPS_VOLUNTEER_URL' do
      ready!(user, segment: 'Pilier')
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('NEXT_STEPS_VOLUNTEER_URL').and_return('https://example.org/benevoles')

      get :current, params: { token: user.token }

      expect(result['next_step']).to include('kind' => 'become_ambassador', 'link' => 'https://example.org/benevoles')
    end

    it 'gives no link to the become-volunteer gesture when NEXT_STEPS_VOLUNTEER_URL is not set' do
      ready!(user, segment: 'Pilier')
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('NEXT_STEPS_VOLUNTEER_URL').and_return(nil)

      get :current, params: { token: user.token }

      expect(result['next_step']).to include('kind' => 'become_ambassador', 'link' => nil)
    end

    it 'gives the 3 contents of a mini-path' do
      ready!(user, segment: 'Silencieux', sub_segment: 'À activer')
      resources = create_list(:resource, 3)

      get :current, params: { token: user.token }

      expect(result['next_step']['kind']).to eq('content_path')
      expect(result['next_step']['targets'].map { |resource| resource['id'] }).to eq(resources.map(&:id))
    end
  end
end
