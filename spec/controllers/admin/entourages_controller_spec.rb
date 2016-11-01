require 'rails_helper'
include AuthHelper

describe Admin::EntouragesController do

  let!(:user) { admin_basic_login }

  describe 'GET #index' do
    context "has entourages" do
      let!(:entourage_list) { FactoryGirl.create_list(:entourage, 2) }
      before { get :index }

      it { expect(assigns(:entourages)).to match_array(entourage_list) }
    end

    context "has no entourages" do
      before { get :index }
      it { expect(assigns(:entourages)).to eq([]) }
    end
  end

  describe "GET #show" do
    let!(:entourage) { FactoryGirl.create(:entourage) }
    before { get :show, id: entourage.to_param }
    it { expect(assigns(:entourage)).to eq(entourage) }
  end

end
