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
        interests: neighborhood.interests,
        photo_url: neighborhood.photo_url
      }, format: :json }}

      it { expect(response.status).to eq(201) }
      it { expect(subject.name).to eq neighborhood.name }
      it { expect(subject.latitude).to eq neighborhood.latitude }
      it { expect(subject.longitude).to eq neighborhood.longitude }
      it { expect(subject.adress).to eq neighborhood.adress }

      it "renders POI" do
        expect(result).to eq("neighborhood" => {
          "uuid" => subject.id.to_s
        })
      end
    end

    describe 'show' do
      let(:neighborhood) { create :neighborhood }
      before { get 'show', params: { id: neighborhood.id, token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(JSON.parse(response.body)).to eq(
        "neighborhood" => {
          "name" => neighborhood.name,
        }
      )}
    end
  end
end
