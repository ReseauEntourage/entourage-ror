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

  describe "POST create action" do
    let(:success) {
      post :create, params: { entourage: {
        group_type: 'action',
        title: 'Groupe de voisins',
        description: 'Description du groupe de voisins',
        latitude: 1,
        longitude: 2,
        entourage_type: 'ask_for_help',
        display_category: 'social',
      }}
    }

    it { expect { success }.to change { Entourage.where(group_type: :action).count }.by(1) }
  end

  describe "POST create outing" do
    let(:success) {
      post :create, params: { entourage: {
        group_type: :outing,
        title: 'Groupe de voisins',
        description: 'Groupe de voisins',
        entourage_type: 'ask_for_help',
        display_category: 'social',
        latitude: 1,
        longitude: 2,
        metadata: {
          starts_at: {
            date: "2018-09-04",
            hour: 7,
            min: 30,
          },
          ends_at: {
            date: "2018-09-05",
            hour: 7,
            min: 30,
          },
          google_place_id: "ChIJFzXXy-xt5kcRg5tztdINnp0",
          place_name: "Le Dorothy",
          street_address: "85 bis rue de Ménilmontant, 75020 Paris, France",
        },
      }}
    }

    it { expect { success }.to change { Entourage.where(group_type: :outing).count }.by(1) }
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

  describe "GET #edit_image" do
    context "no access when action" do
      let(:entourage) { FactoryBot.create(:entourage) }
      before { get :edit_image, params: { id: entourage.to_param } }
      it { should redirect_to edit_admin_entourage_path(entourage) }
      it { expect(response.code).to eq('302') }
    end

    context "access when outing" do
      let(:outing) { FactoryBot.create(:outing) }
      before { get :edit_image, params: { id: outing.to_param } }
      it { should_not redirect_to edit_admin_entourage_path(outing) }
      it { expect(response.code).to eq('200') }
    end
  end

  describe "PUT #update_image" do
    let(:entourage_image) { FactoryBot.create(:entourage_image) }

    context "no access when action" do
      let(:entourage) { FactoryBot.create(:entourage) }
      it {
        expect_any_instance_of(Entourage).not_to receive(:save)
        put :update_image, params: { id: entourage.to_param, entourage: { entourage_image_id: entourage_image.id } }
      }
    end

    context "access when outing" do
      let(:outing) { FactoryBot.create(:outing) }
      it {
        expect_any_instance_of(Entourage).to receive(:save)
        put :update_image, params: { id: outing.to_param, entourage: { entourage_image_id: entourage_image.id } }
      }
    end
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
