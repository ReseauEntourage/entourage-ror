require 'rails_helper'

describe Api::V1::Users::OutingsController, type: :controller do
  render_views

  let(:user) { create(:pro_user) }
  let(:result) { JSON.parse(response.body) }

  describe 'GET index' do
    let!(:outing_jo) { create(:outing, user: user, title: 'JO Paris', participants: [user],
      metadata: {
        starts_at: 1.minute.from_now,
        ends_at: 2.minutes.from_now
      }
    )}
    let!(:outing_tdf) { create(:outing, title: 'Tour de France', participants: [user],
      metadata: {
        starts_at: 1.hour.from_now,
        ends_at: 2.hours.from_now
      }
    )}
    let!(:outing_not_member) { create(:outing,
      metadata: {
        starts_at: 1.minute.from_now,
        ends_at: 2.minutes.from_now
      }
    )}

    context 'not logged in' do
      before { get :index, params: { user_id: user.id } }
      it { expect(response.status).to eq(401) }
    end

    context 'logged in' do
      before { get :index, params: { user_id: user.id, token: user.token } }

      it { expect(response.status).to eq(200) }
      it { expect(result['outings'].count).to eq(2) }
      it { expect(result['outings'].map {|outings| outings['id']}).to match_array([outing_tdf.id, outing_jo.id]) }
    end

    describe 'filter by interests' do
      before { Outing.find(outing_tdf.id).update_attribute(:interest_list, ['sport']) }

      before { get :index, params: { user_id: user.id, token: user.token, interests: interests } }

      describe 'find with interest' do
        let(:interests) { ['sport'] }

        it { expect(response.status).to eq 200 }
        it { expect(result['outings'].count).to eq(1) }
        it { expect(result['outings'][0]['id']).to eq(outing_tdf.id) }
      end

      describe 'does not find with interest' do
        let(:interests) { ['jeux'] }

        it { expect(response.status).to eq 200 }
        it { expect(result['outings'].count).to eq(0) }
      end
    end

    describe 'filter by q' do
      before { get :index, params: { user_id: user.id, token: user.token, q: q } }

      describe 'find with q' do
        let(:q) { 'JO' }

        it { expect(response.status).to eq 200 }
        it { expect(result['outings'].count).to eq(1) }
        it { expect(result['outings'][0]['id']).to eq(outing_jo.id) }
      end

      describe 'find with q not case sensitive' do
        let(:q) { 'jo' }

        it { expect(response.status).to eq 200 }
        it { expect(result['outings'].count).to eq(1) }
        it { expect(result['outings'][0]['id']).to eq(outing_jo.id) }
      end

      describe 'does not find with q' do
        let(:q) { 'OJ' }

        it { expect(response.status).to eq 200 }
        it { expect(result['outings'].count).to eq(0) }
      end
    end
  end

  describe 'GET past' do
    let!(:outing_jo) { create(:outing, user: user, title: 'JO Paris', participants: [user],
      metadata: {
        starts_at: 25.days.ago,
        ends_at: 25.days.ago + 1.minute
      }
    )}
    let!(:outing_tdf) { create(:outing, title: 'Tour de France', participants: [user],
      metadata: {
        starts_at: 1.month.ago,
        ends_at: 1.month.ago + 1.minute
      }
    )}
    let!(:outing_not_member) { create(:outing,
      metadata: {
        starts_at: 1.month.ago,
        ends_at: 1.month.ago + 1.minute
      }
    )}
    let!(:outing_in_future) { create(:outing, participants: [user],
      metadata: {
        starts_at: 1.day.from_now,
        ends_at: 1.day.from_now + 1.minute
      }
    )}

    context 'not logged in' do
      before { get :past, params: { user_id: user.id } }
      it { expect(response.status).to eq(401) }
    end

    context 'logged in' do
      before { get :past, params: { user_id: user.id, token: user.token } }

      it { expect(response.status).to eq(200) }
      it { expect(result['outings'].count).to eq(2) }
      it { expect(result['outings'].map {|outings| outings['id']}).to eq([outing_tdf.id, outing_jo.id]) }
    end

    describe 'filter by interests' do
      before { Outing.find(outing_tdf.id).update_attribute(:interest_list, ['sport']) }

      before { get :past, params: { user_id: user.id, token: user.token, interests: interests } }

      describe 'find with interest' do
        let(:interests) { ['sport'] }

        it { expect(response.status).to eq 200 }
        it { expect(result['outings'].count).to eq(1) }
        it { expect(result['outings'][0]['id']).to eq(outing_tdf.id) }
      end

      describe 'does not find with interest' do
        let(:interests) { ['jeux'] }

        it { expect(response.status).to eq 200 }
        it { expect(result['outings'].count).to eq(0) }
      end
    end

    describe 'filter by q' do
      before { get :past, params: { user_id: user.id, token: user.token, q: q } }

      describe 'find with q' do
        let(:q) { 'JO' }

        it { expect(response.status).to eq 200 }
        it { expect(result['outings'].count).to eq(1) }
        it { expect(result['outings'][0]['id']).to eq(outing_jo.id) }
      end

      describe 'find with q not case sensitive' do
        let(:q) { 'jo' }

        it { expect(response.status).to eq 200 }
        it { expect(result['outings'].count).to eq(1) }
        it { expect(result['outings'][0]['id']).to eq(outing_jo.id) }
      end

      describe 'does not find with q' do
        let(:q) { 'OJ' }

        it { expect(response.status).to eq 200 }
        it { expect(result['outings'].count).to eq(0) }
      end
    end
  end
end
