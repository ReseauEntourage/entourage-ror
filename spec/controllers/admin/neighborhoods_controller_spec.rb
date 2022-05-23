require 'rails_helper'
include AuthHelper

describe Admin::NeighborhoodsController do
  let!(:user) { admin_basic_login }

  describe 'GET #index' do
    let(:result) { assigns(:neighborhoods).map(&:id) }

    context "has neighborhoods" do
      let!(:neighborhood_list) { FactoryBot.create_list(:neighborhood, 2) }
      before { get :index }

      it { expect(result).to match_array(neighborhood_list.map(&:id)) }
    end

    context "has no neighborhoods" do
      before { get :index }
      it { expect(result).to eq([]) }
    end
  end

  describe "GET #edit" do
    let!(:neighborhood) { FactoryBot.create(:neighborhood) }
    before { get :edit, params: { id: neighborhood.to_param } }

    it { expect(assigns(:neighborhood).id).to eq(neighborhood.id) }
  end

  describe "PUT #update" do
    let!(:neighborhood) { FactoryBot.create(:neighborhood, name: 'foo') }

    context "common field" do
      before {
        put :update, params: { id: neighborhood.id, neighborhood: { name: 'bar' } }
        neighborhood.reload
      }
      it { expect(neighborhood.name).to eq('bar')}
    end
  end
end
