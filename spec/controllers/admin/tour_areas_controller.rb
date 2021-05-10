require 'rails_helper'
include AuthHelper

describe Admin::TourAreasController do
  let!(:user) { admin_basic_login }

  describe 'GET #index' do
    context "has tour_areas" do
      let!(:tour_area_list) { FactoryBot.create_list(:tour_area, 2) }
      before { get :index }

      it { expect(assigns(:tour_areas)).to match_array(tour_area_list) }
    end

    context "has no tour_areas" do
      before { get :index }
      it { expect(assigns(:tour_areas)).to eq([]) }
    end
  end

  describe "GET #new" do
    before { get :new }
    it { expect(assigns(:tour_area)).to be_a_new(TourArea) }
  end

  describe "POST #create" do
    context "create success" do
      let(:tour_area) { post :create, params: { 'tour_area' => {
        departement: '75',
        area: 'Paris',
        status: 'active',
        email: 'paris@paris.fr'
      } } }
      it { expect { tour_area }.to change { TourArea.count }.by(1) }
    end

    context "create failure" do
      let(:tour_area) { post :create, params: { 'tour_area' => {
        departement: nil,
        area: 'Paris',
        status: 'active',
        email: 'paris@paris.fr'
      } } }
        it { expect { tour_area }.to change { TourArea.count }.by(0) }
    end
  end

  describe "GET #edit" do
    let!(:tour_area) { FactoryBot.create(:tour_area) }
    before { get :edit, params: { id: tour_area.to_param } }
    it { expect(assigns(:tour_area)).to eq(tour_area) }
  end

  describe "PUT #update" do
    let!(:tour_area) { FactoryBot.create(:tour_area) }

    context "common field" do
      before {
        put :update, params: { id: tour_area.id, tour_area: { area: 'Nantes' } }
        tour_area.reload
      }
      it { expect(tour_area.area).to eq('Nantes')}
    end
  end

  describe "DELETE destroy" do
    let!(:tour_area) { FactoryBot.create(:tour_area) }
    before { delete :destroy, params: { id: tour_area.id } }
    it { expect(TourArea.count).to eq(0) }
  end
end
