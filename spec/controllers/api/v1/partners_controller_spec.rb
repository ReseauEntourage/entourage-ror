require 'rails_helper'

RSpec.describe Api::V1::PartnersController, type: :controller do
  let!(:user) { create :pro_user }

  describe 'GET index' do
    let!(:partner_paris) { create(:partner, name: 'Entourage Paris') }
    let!(:partner_lyon) { create(:partner, name: 'Entourage Lyon', address: '69000 Lyon') }
    let(:results) { JSON.parse(response.body) }

    before { get 'index', params: { token: user.token, query: query } }

    context 'without filter' do
      let(:query) {}

      it { expect(results).to eq({
        'partners' => [{
          'id' => partner_lyon.id,
          'name' => 'Entourage Lyon',
          'postal_code' => '69000'
        }, {
          'id' => partner_paris.id,
          'name' => 'Entourage Paris',
          'postal_code' => nil
        }]}
      )}
    end

    context 'with filter' do
      let(:query) { 'Paris' }

      it { expect(results['partners'].count).to eq(1) }
      it { expect(results['partners'][0]['id']).to eq(partner_paris.id) }
    end
  end

  describe 'GET show' do
    let!(:partner1) { create(:partner, name: 'Partner A', address: '75008 Paris') }
    let!(:following) { nil }

    before { get 'show', params: { id: partner1.id, token: user.token } }
    # TODO(partner)
    it { expect(JSON.parse(response.body)).to eq(
      'partner' => {
        'id' => partner1.id,
        'name' => 'Partner A',
        'large_logo_url' => 'MyString',
        'small_logo_url' => 'https://s3-eu-west-1.amazonaws.com/entourage-ressources/check-small.png',
        'description' => 'MyDescription',
        'donations_needs' => nil,
        'volunteers_needs' => nil,
        'phone' => nil,
        'address' => '75008 Paris',
        'website_url' => nil,
        'email' => nil,
        'default' => true,
        'following' => false
      }
    )}

    context 'followed' do
      let!(:following) { create :following, user: user, partner: partner1 }
      it { expect(JSON.parse(response.body)).to match(
        'partner' => hash_including(
          'following' => true
        )
      )}
    end
  end

  describe 'POST create' do
    let(:result) { JSON.parse(response.body) }

    let(:request) { post :create, params: { token: user.token }.merge(params) }

    let(:params) { { partner: {
      name: 'Entourage Nantes',
      description: 'Entourage Nantes',
      phone: '02 40 00 01 02',
      address: 'place du Commerce 44000 Nantes',
      website_url: 'https://entourage.social/nantes',
      email: 'nantes@entourage.social',
      latitude: 44,
      longitude: 0.00,
      donations_needs: 'many',
      volunteers_needs: 'plenty',
      staff: false
    }}}

    describe 'creation' do
      before { request }
      before { user.reload }

      it { expect(response.status).to(eq(200)) }
      it { expect(result['partner']['name']).to(eq('Entourage Nantes')) }
      it { expect(user.association?).to(eq(true)) }
      it { expect(user.partner.name).to(eq('Entourage Nantes')) }
    end

    describe 'missing mandatory field' do
      before { params[:partner][:name] = nil }
      before { request }

      it { expect(response.status).to eq(400) }
    end

    describe 'same address different name' do
      let!(:partner) { create(:partner, name: 'Entourage Paris', address: 'place du Commerce 44000 Nantes') }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(result['partner']['name']).to eq('Entourage Nantes') }
    end

    describe 'same name different place' do
      let!(:partner) { create(:partner, name: 'Entourage Nantes', address: 'place du Commerce 35000 Rennes') }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(result['partner']['name']).to eq('Entourage Nantes') }
    end

    describe 'same name same place' do
      let!(:partner) { create(:partner, name: 'Entourage Nantes', address: 'place du Commerce 44000 Nantes') }

      before { request }

      it { expect(response.status).to eq(400) }
    end
  end

  describe 'POST join' do
    let!(:partner) { create(:partner) }
    let(:request) { post :join, params: { token: user.token, partner_id: partner.id } }

    describe 'successful join' do
      before { request }
      before { user.reload }

      it { expect(response.status).to eq(200) }
      it { expect(user.partner_id).to eq(partner.id) }
    end

    describe 'invalid partner' do
      let(:invalid_partner_id) { Partner.last.id + 1 }
      let(:request) { post :join, params: { token: user.token, partner_id: invalid_partner_id } }

      before { request }
      before { user.reload }

      it { expect(response.status).to(eq(400)) }
      it { expect(user.partner_id).to be_nil }
    end

    describe 'missing partner_id' do
      let(:request) { post :join, params: { token: user.token } }

      before { request }
      before { user.reload }

      it { expect(response.status).to(eq(400)) }
      it { expect(user.partner).to be_nil }
    end
  end
end
