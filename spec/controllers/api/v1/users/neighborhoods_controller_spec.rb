require 'rails_helper'

describe Api::V1::Users::NeighborhoodsController, :type => :controller do
  render_views

  let(:user) { create(:pro_user) }
  let(:result) { JSON.parse(response.body) }

  describe 'GET index' do
    let!(:neighborhood) { create(:neighborhood, user: user, latitude: latitude, longitude: longitude, name: "JO Paris", interest_list: ["sport"]) }
    let!(:neighborhood_joined) { create(:neighborhood, latitude: 45, longitude: 0, name: "Tour de France", participants: [user], interest_list: ["nature"]) }
    let!(:neighborhood_other) { create(:neighborhood, latitude: 47, longitude: 0) }

    let(:latitude) { 48.85 }
    let(:longitude) { 2.27 }

    context "not logged in" do
      before { get :index, params: { user_id: user.id } }
      it { expect(response.status).to eq(401) }
    end

    context "logged in" do
      before { get :index, params: { user_id: user.id, token: user.token } }

      it { expect(response.status).to eq(200) }
      it { expect(result["neighborhoods"].count).to eq(2) }
      it { expect(result["neighborhoods"].map {|neighborhoods| neighborhoods["id"]}).to eq([neighborhood.id, neighborhood_joined.id]) }
    end

    describe 'filter by interests' do
      before { get :index, params: { user_id: user.id, token: user.token, interests: interests } }

      describe 'find with interest' do
        let(:interests) { ["sport"] }

        it { expect(response.status).to eq 200 }
        it { expect(result['neighborhoods'].count).to eq(1) }
        it { expect(result['neighborhoods'][0]['id']).to eq(neighborhood.id) }
      end

      describe 'does not find with interest' do
        let(:interests) { ["jeux"] }

        it { expect(response.status).to eq 200 }
        it { expect(result['neighborhoods'].count).to eq(0) }
      end
    end

    describe 'filter by q' do
      before { get :index, params: { user_id: user.id, token: user.token, q: q } }

      describe 'find with q' do
        let(:q) { "JO" }

        it { expect(response.status).to eq 200 }
        it { expect(result['neighborhoods'].count).to eq(1) }
        it { expect(result['neighborhoods'][0]['id']).to eq(neighborhood.id) }
      end

      describe 'find with q not case sensitive' do
        let(:q) { "jo" }

        it { expect(response.status).to eq 200 }
        it { expect(result['neighborhoods'].count).to eq(1) }
        it { expect(result['neighborhoods'][0]['id']).to eq(neighborhood.id) }
      end

      describe 'does not find with q' do
        let(:q) { "OJ" }

        it { expect(response.status).to eq 200 }
        it { expect(result['neighborhoods'].count).to eq(0) }
      end
    end

    describe "filter by localisation" do
      context "params coordinates matches" do
        let(:request) { get :index, params: { user_id: user.id, token: user.token, latitude: 48.84, longitude: 2.28, travel_distance: 10 } }

        before { request }

        it { expect(response.status).to eq(200) }
        it { expect(result["neighborhoods"].count).to eq(1) }
        it { expect(result['neighborhoods'][0]['id']).to eq(neighborhood.id) }
      end

      context "params coordinates do not matches" do
        let(:request) { get :index, params: { user_id: user.id, token: user.token, latitude: 47, longitude: 2, travel_distance: 1 } }

        before { request }

        it { expect(response.status).to eq(200) }
        it { expect(result["neighborhoods"].count).to eq(0) }
      end

      context "do not filter by localisation when no distance in params" do
        let(:request) { get :index, params: { user_id: user.id, token: user.token, latitude: 50, longitude: 50 } }

        before { request }

        it { expect(response.status).to eq(200) }
        it { expect(result["neighborhoods"].count).to eq(2) }
      end
    end
  end
end
