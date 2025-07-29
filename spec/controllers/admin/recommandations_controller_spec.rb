require 'rails_helper'
include AuthHelper

describe Admin::RecommandationsController do
  let!(:user) { admin_basic_login }

  describe 'GET #index' do
    context 'has recommandations' do
      let!(:recommandation_list) { [FactoryBot.create(:recommandation_neighborhood, position_offer_help: 0), FactoryBot.create(:recommandation_neighborhood, position_offer_help: 1)] }
      before { get :index }

      it { expect(assigns(:recommandations)).to match_array(recommandation_list) }
    end

    context 'has no recommandations' do
      before { get :index }
      it { expect(assigns(:recommandations)).to eq([]) }
    end
  end

  describe 'GET #new' do
    before { get :new }
    it { expect(assigns(:recommandation)).to be_a_new(Recommandation) }
    it { expect(response.code).to eq('200') }
  end

  describe 'POST #create' do
    context 'create success' do
      let(:recommandation) { post :create, params: { 'recommandation' => {
        name: 'my_profile',
        image_url: 'path/to/image',
        profile: :ask_for_help,
        instance: :profile,
        action: :show,
        areas: [:dep_75],
        user_goals: [:ask_for_help]
      } } }
      it { expect { recommandation }.to change { Recommandation.count }.by(1) }
    end
  end

  describe 'GET #edit' do
    let!(:recommandation) { FactoryBot.create(:recommandation_neighborhood) }
    before { get :edit, params: { id: recommandation.to_param } }
    it { expect(assigns(:recommandation)).to eq(recommandation) }
  end

  describe 'PUT #update' do
    let!(:recommandation) { FactoryBot.create(:recommandation_neighborhood) }

    context 'common field' do
      before {
        put :update, params: { id: recommandation.id, recommandation: { name: 'new_name' } }
        recommandation.reload
      }
      it { expect(recommandation.name).to eq('new_name')}
    end
  end
end
