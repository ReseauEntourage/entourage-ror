require 'rails_helper'

describe Api::V1::NeighborhoodImagesController do
  let(:user) { FactoryBot.create(:public_user) }

  describe "GET index" do
    let!(:neighborhood_image_list) { FactoryBot.create_list(:neighborhood_image, 2) }

    context "not signed in" do
      before { get :index }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      before { get :index, params: { token: user.token } }
      subject { JSON.parse(response.body) }

      it { expect(response.status).to eq(200) }
      it { expect(subject['neighborhood_images'].count).to eq(2) }
      it {
        expect(
          subject['neighborhood_images'].map do |neighborhood_image|
            neighborhood_image['id']
          end
        ).to match_array(neighborhood_image_list.map(&:id))
      }
    end
  end

  describe "GET show" do
    let(:neighborhood_image) { FactoryBot.create(:neighborhood_image) }

    before { get :show, params: { token: user.token, id: neighborhood_image.id } }
    subject { JSON.parse(response.body) }

    it { expect(subject['neighborhood_image']['id']).to eq(neighborhood_image.id) }
  end
end
