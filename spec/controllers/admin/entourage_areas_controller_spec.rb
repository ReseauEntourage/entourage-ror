require 'rails_helper'
include AuthHelper

describe Admin::EntourageAreasController do
  let!(:super_admin) { super_admin_basic_login }

  describe 'GET #index' do
    before { get :index }

    context "has entourage_areas" do
      let!(:entourage_area_list) { create_list(:entourage_area, 2) }

      it { expect(assigns(:entourage_areas).map(&:id)).to match_array(entourage_area_list.map(&:id)) }
    end

    context "has no entourage_areas" do
      it { expect(assigns(:entourage_areas).count).to eq(0) }
    end
  end

  describe "PUT #update" do
    let!(:entourage_area) { create(:entourage_area, postal_code: "44") }

    before { put :update, params: { id: entourage_area.id, entourage_area: { postal_code: value } } }
    before { entourage_area.reload }

    context "postal_code with 99" do
      let(:value) { "99" }
      it { expect(entourage_area.postal_code).to eq("99") }
    end
  end

  describe "DELETE destroy" do
    let!(:entourage_area) { create(:entourage_area) }

    before { delete :destroy, params: { id: entourage_area.id } }

    it { expect(EntourageArea.count).to eq(0) }
  end
end
