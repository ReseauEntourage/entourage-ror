require 'rails_helper'

describe Api::V1::OutingsController do
  let(:user) { FactoryBot.create(:public_user) }
  let(:neighborhood_1) { create :neighborhood }
  let(:neighborhood_2) { create :neighborhood }

  subject { JSON.parse(response.body) }

  describe 'GET index' do
    let!(:outing) { FactoryBot.create(:outing, status: "open") }
    let!(:neighborhood_outing) { FactoryBot.create(:outing, :joined, user: user, status: "open", neighborhoods: [neighborhood_1]) }


    before { get :index, params: { token: user.token } }

    it { expect(response.status).to eq(200) }
    it { expect(subject).to have_key("outings") }
    it { expect(subject["outings"].count).to eq(2) }
  end

  describe 'POST create' do
    let(:params) { {
      title: "Apéro Entourage",
      # description: "Apéro Entourage",
      # event_url: 'bar',
      latitude: 48.868959,
      longitude: 2.390185,
      neighborhood_ids: [neighborhood_1.id, neighborhood_2.id],
      interests: ['animaux', 'other'],
      other_interest: 'poterie',
      metadata: {
        starts_at: "2018-09-04T19:30:00+02:00",
        ends_at: "2018-09-04T20:30:00+02:00",
        place_name: "Le Dorothy",
        street_address: "85 bis rue de Ménilmontant, 75020 Paris, France",
        google_place_id: "ChIJFzXXy-xt5kcRg5tztdINnp0",
        place_limit: 5
      }
    } }

    context "not signed in" do
      before { post :create, params: { outing: params } }
      it { expect(response.status).to eq(401) }
      it { expect(Entourage.count).to eq(0) }
    end

    context "not joined" do
      before { post :create, params: { outing: params, token: user.token } }
      it { expect(response.body).to include("User has to be a member of every neighborhoods") }
      it { expect(response.status).to eq(400) }
      it { expect(Entourage.count).to eq(0) }
    end

    context "signed in" do
      let!(:join_request_1) { FactoryBot.create(:join_request, joinable: neighborhood_1, user: user, status: :accepted) }
      let!(:join_request_2) { FactoryBot.create(:join_request, joinable: neighborhood_2, user: user, status: :accepted) }

      context "without all required parameters" do
        before { post :create, params: { outing: {
          title: "foobar",
          longitude: 1.123,
          latitude: 4.567
        }, token: user.token } }

        it { expect(response.status).to eq(400) }
        it { expect(Entourage.count).to eq(0) }
        it { expect(neighborhood_1.outings.count).to eq(0) }
        it { expect(neighborhood_2.outings.count).to eq(0) }
        it { expect(JSON.parse(response.body)).to have_key("message") }
        it { expect(JSON.parse(response.body)).to have_key("reasons") }
      end

      context "with all required parameters" do
        before { post :create, params: { outing: params, token: user.token } }

        it { expect(response.status).to eq(201) }
        it { expect(Entourage.count).to eq(1) }
        it { expect(neighborhood_1.outings.count).to eq(1) }
        it { expect(neighborhood_2.outings.count).to eq(1) }
        it { expect(Outing.last.interest_list).to match_array(["animaux", "other"]) }
        it { expect(Outing.last.other_interest).to eq("poterie") }
        it { expect(Outing.last.metadata[:place_limit].to_i).to eq(5) }
      end

      context "interests are optional" do
        before { post :create, params: { outing: params.except(:interests, :other_interest), token: user.token } }

        it { expect(response.status).to eq(201) }
        it { expect(Entourage.count).to eq(1) }
        it { expect(Outing.last.interest_list).to match_array([]) }
        it { expect(Outing.last.other_interest).to be_nil }
      end

      context "place_limit is nullable" do
        before {
          params[:metadata][:place_limit] = nil
          post :create, params: { outing: params, token: user.token }
        }

        it { expect(response.status).to eq(201) }
        it { expect(Entourage.count).to eq(1) }
        it { expect(Outing.last.metadata[:place_limit]).to be_blank }
      end

      context "place_limit is optional" do
        before {
          params[:metadata] = params[:metadata].except(:place_limit)
          post :create, params: { outing: params, token: user.token }
        }

        it { expect(response.status).to eq(201) }
        it { expect(Entourage.count).to eq(1) }
        it { expect(Outing.last.metadata[:place_limit]).to be_blank }
      end
    end
  end

  describe 'GET show' do
    let(:outing) { FactoryBot.create(:outing, status: "open") }

    before { get :show, params: { token: user.token, id: outing.id } }

    it { expect(response.status).to eq 200 }
    it { expect(subject).to have_key("outing") }
  end
end
