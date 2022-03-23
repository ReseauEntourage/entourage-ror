require 'rails_helper'

describe Api::V1::NeighborhoodsController, :type => :controller do
  render_views

  context 'authorized' do
    let!(:user) { create :pro_user }

    describe 'index' do
      let!(:neighborhood) { create :neighborhood }
      let(:result) { JSON.parse(response.body) }

      before { get :index, params: { token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result).to have_key('neighborhoods') }
    end

    describe 'create' do
      let!(:neighborhood) { build :neighborhood }

      let(:subject) { Neighborhood.last }
      let(:result) { JSON.parse(response.body) }

      before { post :create, params: { token: user.token, neighborhood: {
        name: neighborhood.name,
        ethics: neighborhood.ethics,
        latitude: neighborhood.latitude,
        longitude: neighborhood.longitude,
        interests: neighborhood.interest_list,
        photo_url: neighborhood.photo_url
      }, format: :json }}

      it { expect(response.status).to eq(201) }
      it { expect(subject.name).to eq neighborhood.name }
      it { expect(subject.latitude).to eq neighborhood.latitude }
      it { expect(subject.longitude).to eq neighborhood.longitude }
      it { expect(result).to have_key("neighborhood") }
      it { expect(result['neighborhood']['name']).to eq("Foot Paris 17è") }
    end

    describe 'show' do
      let(:neighborhood) { create :neighborhood }
      before { get 'show', params: { id: neighborhood.id, token: user.token } }

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
