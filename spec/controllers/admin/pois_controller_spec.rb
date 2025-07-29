require 'rails_helper'
include AuthHelper

describe Admin::PoisController do

  let!(:user) { admin_basic_login }

  describe 'GET #index' do
    context 'has pois' do
      let!(:poi_list) { FactoryBot.create_list(:poi, 2) }
      before { get :index, params: { moderator_id: :any } }

      it { expect(assigns(:pois)).to match_array(poi_list) }
    end

    context 'has no pois' do
      before { get :index, params: { moderator_id: :any } }

      it { expect(assigns(:pois)).to eq([]) }
    end
  end

  describe 'PUT #update' do
    let!(:category_1) { FactoryBot.create(:category) }
    let!(:category_2) { FactoryBot.create(:category) }
    let!(:poi) { FactoryBot.create(:poi, latitude: 1, longitude: 1) }
    before { put :update, params: { id: poi.id, poi: { latitude: 1, longitude: 1, category_ids: [category_1.id, category_2.id] } } }
    it { expect(poi.reload.categories).to eq([category_1, category_2]) }
  end
end
