require 'rails_helper'
include AuthHelper

describe Admin::EntouragesController do

  let!(:user) { admin_basic_login }
  let!(:main_moderator) { create :admin_user }

  describe 'GET #index' do
    context "has entourages" do
      let!(:entourage_list) { FactoryBot.create_list(:entourage, 2, :joined) }
      before { get :index, params: { moderator_id: :any } }

      it { expect(assigns(:entourages)).to match_array(entourage_list) }
    end

    context "has no entourages" do
      before { get :index, params: { moderator_id: :any } }
      it { expect(assigns(:entourages)).to eq([]) }
    end
  end

  describe "GET #show" do
    let(:entourage) { FactoryBot.create(:entourage) }
    before { get :show, params: { id: entourage.to_param } }
    it { expect(assigns(:entourage)).to eq(entourage) }
  end

  describe "GET #show_members" do
    let(:entourage) { FactoryBot.create(:entourage) }
    before { get :show_members, params: { id: entourage.to_param } }
    it { expect(assigns(:entourage)).to eq(entourage) }
  end

  describe "GET #show_joins" do
    let(:entourage) { FactoryBot.create(:entourage) }
    before { get :show_joins, params: { id: entourage.to_param } }
    it { expect(assigns(:entourage)).to eq(entourage) }
  end

  describe "GET #show_invitations" do
    let(:entourage) { FactoryBot.create(:entourage) }
    before { get :show_invitations, params: { id: entourage.to_param } }
    it { expect(assigns(:entourage)).to eq(entourage) }
  end

  describe "GET #show_messages" do
    let(:entourage) { FactoryBot.create(:entourage) }
    before { get :show_messages, params: { id: entourage.to_param } }
    it { expect(assigns(:entourage)).to eq(entourage) }
  end

  describe "POST update pins" do
    let(:entourage) { FactoryBot.create(:entourage, pin: true) }
    before { post :update, params: { id: entourage.to_param, entourage: { pins: ['75000','44'], group_type: :action } } }

    it { expect(assigns(:entourage).pins).to match_array(['75000', '44']) }
  end

  describe "POST pin" do
    let(:entourage) { FactoryBot.create(:entourage, pin: false) }
    before { post :pin, params: { id: entourage.to_param } }

    it { expect(assigns(:entourage).pin?).to eq(true) }
  end

  describe "POST unpin" do
    let(:entourage) { FactoryBot.create(:entourage, pin: true) }
    before { post :unpin, params: { id: entourage.to_param } }

    it { expect(assigns(:entourage).pin?).to eq(false) }
  end
end
