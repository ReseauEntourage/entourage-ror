require 'rails_helper'

RSpec.describe Api::V1::PartnersController, type: :controller do
  let!(:user) { create :pro_user, travel_distance: 1000 }

  before { User.any_instance.stub(:departement).and_return(75) }
  before { User.any_instance.stub(:latitude).and_return(48.8566) }
  before { User.any_instance.stub(:longitude).and_return(2.35) }

  describe 'GET index' do
    let!(:partner_paris) { create(:partner, name: 'Entourage Paris') }
    let!(:partner_lyon) { create(:partner, name: 'Entourage Lyon') }
    let(:results) { JSON.parse(response.body) }

    before { get 'index', params: { token: user.token, query: query } }

    context 'without filter' do
      let(:query) {}

      it { expect(results).to eq({
        'partners' => [{
          'id' => partner_lyon.id,
          'name' => 'Entourage Lyon',
          'postal_code' => nil
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
        'image_url' => 'https://foobar.s3.eu-west-1.amazonaws.com/partners/logo/MyString',
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
      address: 'place du Commerce 44000 Nantes',
      latitude: 44,
      longitude: 0.00
    }}}

    describe 'creation' do
      before { request }
      before { user.reload }

      it { expect(response.status).to(eq(200)) }
      it { expect(result['partner']['name']).to(eq('Entourage Nantes')) }
      it { expect(user.association?).to(eq(true)) }
      it { expect(user.partner.name).to(eq('Entourage Nantes')) }
      it { expect(user.partner.orientation_list).to(eq(['guide'])) }
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

      before { Partner.any_instance.stub(:postal_code).and_return('44000') }
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

  describe 'PUT update' do
    let(:result) { JSON.parse(response.body) }
    let(:partner) { create(:partner, users: users) }
    let(:users) { [user] }

    before { allow(SlackServices::PartnerUpdate).to receive_message_chain(:new, :notify) }
    before { post :update, params: { id: partner.id, token: user.token, partner: { image_url: 'foobar.png' }} }

    describe 'user is a partner member' do
      it { expect(response.status).to eq(200) }
      it { expect(partner.reload.image_url).to eq('foobar.png') }
    end

    describe 'user is not a partner member' do
      let(:users) { [] }

      it { expect(response.status).to eq(401) }
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

  describe 'POST presigned_upload' do
    let!(:partner) { create(:partner) }
    let(:result) { JSON.parse(response.body) }

    before { post :presigned_upload, params: { token: user.token, content_type: content_type } }

    describe 'valid content_type' do
      let(:content_type) { 'image/jpeg' }

      it { expect(response.status).to eq(200) }
      it { expect(result).to have_key("upload_key") }
      it { expect(result).to have_key("presigned_url") }
      it { expect(result["upload_key"]).to match("jpeg") }
      it { expect(result["presigned_url"]).to match(Partner.bucket_prefix) }
    end

    describe 'invalid content_type' do
      let(:content_type) { 'image/wrong' }

      it { expect(response.status).to(eq(400)) }
    end
  end
end
