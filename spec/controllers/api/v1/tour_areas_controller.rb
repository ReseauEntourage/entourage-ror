require 'rails_helper'

describe Api::V1::TourAreasController do
  let(:user) { FactoryBot.create(:public_user) }

  describe "GET index" do
    let!(:tour_area_list) { FactoryBot.create_list(:tour_area, 2) }

    context "not signed in" do
      before { get :index }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      before { get :index, params: { token: user.token } }
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
    let(:tour_area) { FactoryBot.create(:tour_area) }

    before { get :show, params: { token: user.token, id: tour_area.id } }
    subject { JSON.parse(response.body) }
    it { expect(subject['tour_area']['id']).to eq(tour_area.id) }
  end

  describe "POST tour_request" do
    let(:tour_area) { FactoryBot.create(:tour_area) }
    let(:tour_area_inactive) { FactoryBot.create(:tour_area, status: :inactive) }
    subject { JSON.parse(response.body) }

    context "wrong id" do
      before { post :tour_request, params: { token: user.token, id: 0, message: 'I have a dream' } }
      it { expect(response.status).to eq(400) }
      it { expect(subject['code']).to eq('tour_area_not_found') }
    end

    context "wrong status" do
      before { post :tour_request, params: { token: user.token, id: tour_area_inactive.id, message: 'I have a dream' } }
      it { expect(response.status).to eq(400) }
      it { expect(subject['code']).to eq('tour_area_inactive') }
    end

    context "correct id" do
      before { post :tour_request, params: { token: user.token, id: tour_area.id, message: 'I have a dream' } }
      it { expect(response.status).to eq(200) }
    end
  end
end
