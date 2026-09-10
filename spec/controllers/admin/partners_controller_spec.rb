require 'rails_helper'
include AuthHelper

describe Admin::PartnersController do
  let!(:user) { admin_basic_login }

  describe 'GET #index' do
    context 'has partners' do
      let!(:partner_list) { [create(:partner, name: "new partner", address: '75000 Paris'), create(:partner, address: '29000 Brest')] }

      before { get :index }

      it { expect(assigns(:partners).pluck(:id)).to match_array(partner_list.pluck(:id)) }
    end

    context 'has no partners' do
      before { get :index }
      it { expect(assigns(:partners)).to eq([]) }
    end
  end

  describe 'GET #new' do
    before { get :new }

    it { expect(assigns(:partner)).to be_a_new(Partner) }
    it { expect(response.code).to eq('200') }
  end

  describe 'POST #create' do
    let!(:partner) { build(:partner) }

    let(:request) { post :create, params: { 'partner' => {
      name: partner.name,
      description: partner.description,
      latitude: partner.latitude,
      longitude: partner.longitude,
      address: partner.address
    } } }

    context do
      it { expect { request }.to change { Partner.count }.by(1) }
    end

    context do
      before { request }

      it { expect(response.code).to eq('302') }
    end
  end

  describe 'GET #edit' do
    let!(:partner) { create(:partner) }

    before { get :edit, params: { id: partner.to_param } }

    it { expect(assigns(:partner)).to eq(partner) }
  end

  describe 'PUT #update' do
    let!(:partner) { create(:partner) }

    context 'common field' do
      before {
        put :update, params: { id: partner.id, partner: { name: 'new_name' } }
        partner.reload
      }
      it { expect(partner.name).to eq('new_name')}
    end
  end

  describe 'GET #search' do
    let!(:matching) { create(:partner, name: 'Le Rocher Oasis des Cités', address: '75000 Paris') }
    let!(:other) { create(:partner, name: 'Autre association', address: '75000 Paris') }

    before { get :search, params: { query: 'Rocher' }, format: :json }

    it { expect(JSON.parse(response.body).map { |p| p['id'] }).to eq([matching.id]) }
  end
end
