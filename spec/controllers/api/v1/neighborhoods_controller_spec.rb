require 'rails_helper'

describe Api::V1::NeighborhoodsController, :type => :controller do
  render_views

  let(:user) { create :pro_user }

  context 'index' do
    let!(:neighborhood) { create :neighborhood }
    let(:result) { JSON.parse(response.body) }

    describe 'not authorized' do
      before { get :index }

      it { expect(response.status).to eq 401 }
    end

    describe 'authorized' do
      before { get :index, params: { token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result).to have_key('neighborhoods') }
    end
  end

  context 'create' do
    let(:neighborhood) { build :neighborhood }
    let(:fields) { {
        name: neighborhood.name,
        ethics: neighborhood.ethics,
        latitude: neighborhood.latitude,
        longitude: neighborhood.longitude,
        interests: neighborhood.interest_list,
        photo_url: neighborhood.photo_url
    } }

    describe 'not authorized' do
      before { post :create }

      it { expect(response.status).to eq 401 }
    end

    describe 'authorized' do
      let(:subject) { Neighborhood.last }
      let(:result) { JSON.parse(response.body) }

      before { post :create, params: { token: user.token, neighborhood: fields, format: :json }}

      it { expect(response.status).to eq(201) }
      it { expect(subject.name).to eq neighborhood.name }
      it { expect(subject.latitude).to eq neighborhood.latitude }
      it { expect(subject.longitude).to eq neighborhood.longitude }
      it { expect(result).to have_key("neighborhood") }
      it { expect(result['neighborhood']['name']).to eq("Foot Paris 17è") }
    end
  end

  describe 'PATCH update' do
    let(:neighborhood) { FactoryBot.create(:neighborhood) }

    context "not signed in" do
      before { patch :update, params: { id: neighborhood.to_param, neighborhood: { name: "new name" } } }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      before { patch :update, params: { id: neighborhood.to_param, neighborhood: { name: "new name" } } }

      context "user is not creator" do
        before { patch :update, params: { id: neighborhood.to_param, neighborhood: { name: "new name" }, token: user.token } }
        it { expect(response.status).to eq(401) }
      end

      context "user is creator" do
        let(:neighborhood) { FactoryBot.create(:neighborhood, user: user) }
        let(:result) { JSON.parse(response.body) }

        before { patch :update, params: { id: neighborhood.to_param, neighborhood: { name: "new name" }, token: user.token } }
        it { expect(response.status).to eq(200) }
        it { expect(result).to have_key("neighborhood") }
        it { expect(result["neighborhood"]["name"]).to eq("new name") }
      end
    end
  end

  context 'show' do
    let(:neighborhood) { create :neighborhood }

    describe 'not authorized' do
      before { get :show, params: { id: neighborhood.id } }

      it { expect(response.status).to eq 401 }
    end

    describe 'authorized' do
      before { get :show, params: { id: neighborhood.id, token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(JSON.parse(response.body)).to eq({
        "neighborhood" => {
          "id" => neighborhood.id,
          "name" => "Foot Paris 17è",
          "members_count" => 0,
          "photo_url" => nil,
          "interests" => ["sport"],
          "members" => [],
          "ethics" => nil,
          "past_outings_count" => 0,
          "future_outings_count" => 0,
          "has_ongoing_outing" => false
        }
      })}
    end
  end
end
