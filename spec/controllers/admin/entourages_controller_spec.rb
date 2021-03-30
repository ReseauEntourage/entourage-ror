require 'rails_helper'
include AuthHelper

describe Admin::EntouragesController do

  let!(:user) { admin_basic_login }
  let!(:main_moderator) { create :admin_user }

  describe 'GET #index' do
    context "has entourages" do
      let!(:entourage_list) { FactoryGirl.create_list(:entourage, 2, :joined) }
      before { get :index, moderator_id: :any }

      it { expect(assigns(:entourages)).to match_array(entourage_list) }
    end

    context "has no entourages" do
      before { get :index, moderator_id: :any }
      it { expect(assigns(:entourages)).to eq([]) }
    end
  end

  describe "GET #show" do
    let(:entourage) { FactoryGirl.create(:entourage) }
    before { get :show, id: entourage.to_param }

    it { expect(assigns(:entourage)).to eq(entourage) }
  end

  describe "POST update pins" do
    let(:entourage) { FactoryGirl.create(:entourage, pin: true) }
    before { post :update, id: entourage.to_param, entourage: { pins: '75000 44', group_type: :action } }

    it { expect(assigns(:entourage).pins).to match_array(['75000', '44']) }
  end

  describe "POST pin" do
    let(:entourage) { FactoryGirl.create(:entourage, pin: false) }
    before { post :pin, id: entourage.to_param }

    it { expect(assigns(:entourage).pin?).to eq(true) }
  end

  describe "POST unpin" do
    let(:entourage) { FactoryGirl.create(:entourage, pin: true) }
    before { post :unpin, id: entourage.to_param }

    it { expect(assigns(:entourage).pin?).to eq(false) }
  end
end
