require 'rails_helper'

describe Api::V1::Neighborhoods::OutingsController do
  let(:user) { FactoryBot.create(:public_user) }
  let(:neighborhood) { create :neighborhood }

  describe 'POST create' do
    context "not signed in" do
      before { post :create, params: { neighborhood_id: neighborhood.to_param, outing: { title: "foobar", longitude: 1.123, latitude: 4.567 } } }
      it { expect(response.status).to eq(401) }
      it { expect(Entourage.count).to eq(0) }
    end

    context "signed in" do
      context "without all required parameters" do
        before { post :create, params: { neighborhood_id: neighborhood.to_param, outing: {
          title: "foobar",
          longitude: 1.123,
          latitude: 4.567
        }, token: user.token } }

        it { expect(response.status).to eq(400) }
        it { expect(JSON.parse(response.body)).to have_key("message") }
        it { expect(JSON.parse(response.body)).to have_key("reasons") }
      end

      context "with all required parameters" do
        before { post :create, params: { neighborhood_id: neighborhood.to_param, outing: {
          title: 'Groupe de voisins',
          description: 'Groupe de voisins',
          entourage_type: 'ask_for_help',
          display_category: 'social',
          latitude: 1,
          longitude: 2,
          metadata: {
            starts_at: {
              date: "2018-09-04",
              hour: 7,
              min: 30,
            },
            ends_at: {
              date: "2018-09-05",
              hour: 7,
              min: 30,
            },
            google_place_id: "ChIJFzXXy-xt5kcRg5tztdINnp0",
            place_name: "Le Dorothy",
            street_address: "85 bis rue de Ménilmontant, 75020 Paris, France",
          },
        }, token: user.token } }

        it { expect(response.status).to eq(201) }
        it { expect(Entourage.count).to eq(1) }
        it { expect(neighborhood.outings.count).to eq(1) }
      end
    end
  end
end
