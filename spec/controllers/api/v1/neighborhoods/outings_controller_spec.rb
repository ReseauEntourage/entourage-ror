require 'rails_helper'

describe Api::V1::Neighborhoods::OutingsController do
  let(:user) { FactoryBot.create(:public_user) }
  let(:neighborhood) { create :neighborhood }

  describe 'GET index' do
    let!(:outing) { FactoryBot.create(:outing, :joined, user: user, status: :open, neighborhoods: [neighborhood]) }
    let(:request) { get :index, params: { token: user.token, neighborhood_id: neighborhood.to_param } }

    context "not joined" do
      before { request }

      # non-member can list outings
      it { expect(response.status).to eq(200) }
    end

    context "joined" do
      let!(:join_request) { FactoryBot.create(:join_request, joinable: neighborhood, user: user, status: :accepted) }
      subject { JSON.parse(response.body) }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject).to have_key("outings") }
      it { expect(subject["outings"].count).to eq(1) }
      it { expect(subject["outings"][0]["id"]).to eq(outing.id) }
      it { expect(subject["outings"][0]["neighborhoods"]).to match_array([
        { "id" => neighborhood.id, "name" => neighborhood.name }
      ]) }
    end

    context "find online" do
      let!(:online) { FactoryBot.create(:outing, status: :open, online: true) }

      subject { JSON.parse(response.body) }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject).to have_key("outings") }
      it { expect(subject["outings"].count).to eq(2) }
      it { expect(subject["outings"].map{|outing| outing["id"]}).to match_array([outing.id, online.id]) }
    end

    context "does not find offline" do
      let!(:offline) { FactoryBot.create(:outing, status: :open, online: false) }

      subject { JSON.parse(response.body) }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject).to have_key("outings") }
      it { expect(subject["outings"].count).to eq(1) }
      it { expect(subject["outings"][0]["id"]).to eq(outing.id) }
    end
  end

  describe 'POST create' do
    let(:params) { {
      title: "Apéro Entourage",
      # description: "Apéro Entourage",
      # event_url: 'bar',
      latitude: 48.868959,
      longitude: 2.390185,
      metadata: {
        starts_at: 1.day.from_now,
        ends_at: 1.day.from_now + 1.hour,
        place_name: "Le Dorothy",
        street_address: "85 bis rue de Ménilmontant, 75020 Paris, France",
        google_place_id: "ChIJFzXXy-xt5kcRg5tztdINnp0",
      }
    } }

    context "not signed in" do
      before { post :create, params: { neighborhood_id: neighborhood.to_param, outing: params } }
      it { expect(response.status).to eq(401) }
      it { expect(Entourage.count).to eq(0) }
    end

    context "not joined" do
      before { post :create, params: { neighborhood_id: neighborhood.to_param, outing: params, token: user.token } }
      it { expect(response.status).to eq(401) }
      it { expect(Entourage.count).to eq(0) }
    end

    context "signed in" do
      let!(:join_request) { FactoryBot.create(:join_request, joinable: neighborhood, user: user, status: :accepted) }

      context "without all required parameters" do
        before { post :create, params: { neighborhood_id: neighborhood.to_param, outing: {
          title: "foobar",
          longitude: 1.123,
          latitude: 4.567
        }, token: user.token } }

        it { expect(response.status).to eq(400) }
        it { expect(Entourage.count).to eq(0) }
        it { expect(neighborhood.outings.count).to eq(0) }
        it { expect(JSON.parse(response.body)).to have_key("message") }
        it { expect(JSON.parse(response.body)).to have_key("reasons") }
      end

      context "with all required parameters" do
        before { post :create, params: { neighborhood_id: neighborhood.to_param, outing: params, token: user.token } }

        it { expect(response.status).to eq(201) }
        it { expect(Entourage.count).to eq(1) }
        it { expect(neighborhood.outings.count).to eq(1) }
      end
    end
  end
end
