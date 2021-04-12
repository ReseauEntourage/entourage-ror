require 'rails_helper'

describe Api::V1::TourAreasController do
  let(:user) { FactoryGirl.create(:public_user) }

  describe "GET index" do
    let!(:tour_area_list) { FactoryGirl.create_list(:tour_area, 2) }

    context "not signed in" do
      before { get :index }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      before { get :index, token: user.token }
      subject { JSON.parse(response.body) }
      it { expect(response.status).to eq(200) }
      it { expect(subject['tour_areas'].count).to eq(2) }
      it {
        expect(
          subject['tour_areas'].map do |tour_area|
            tour_area['id']
          end
        ).to match_array(tour_area_list.map(&:id))
      }
    end
  end

  describe "GET show" do
    let(:tour_area) { FactoryGirl.create(:tour_area) }

    before { get :show, token: user.token, id: tour_area.id }
    subject { JSON.parse(response.body) }
    it { expect(subject['tour_area']['id']).to eq(tour_area.id) }
  end
end
