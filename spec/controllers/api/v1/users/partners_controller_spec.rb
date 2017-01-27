require 'rails_helper'

RSpec.describe Api::V1::Users::PartnersController, type: :controller do

  let!(:user) { FactoryGirl.create :pro_user }

  describe 'GET index' do
    let!(:partner1) { FactoryGirl.create(:partner) }
    let!(:partner2) { FactoryGirl.create(:partner) }
    before { FactoryGirl.create(:user_partner, user: user, partner: partner1) }

    before { get 'index', {user_id: user.id, token: user.token} }

    it { expect(JSON.parse(response.body)["partners"].map{|p| p["id"]}).to eq([partner1.id])}
  end

  describe 'POST create' do
    let!(:partner) { FactoryGirl.create(:partner) }
    before { post :create, {partner: { id: partner.to_param }, user_id: user.id, token: user.token } }
    it { expect(user.partners).to eq([partner]) }
    it { expect(user.default_partner).to eq(partner) }
  end

  describe 'PUT update' do
    let!(:partner) { FactoryGirl.create(:partner) }

    describe "set default partner" do
      before { FactoryGirl.create(:user_partner, user: user, partner: partner, default: false) }

      before { put :update, {id: partner.to_param, partner: { default: true }, user_id: user.id, token: user.token } }

      it { expect(user.user_partners.first.default).to be true}
    end

    describe "remove default partner" do
      before { FactoryGirl.create(:user_partner, user: user, partner: partner, default: true) }

      before { put :update, {id: partner.to_param, partner: { default: false }, user_id: user.id, token: user.token } }

      it { expect(user.user_partners.first.default).to be false}
    end
  end

  describe 'DELETE destroy' do
    let!(:partner) { FactoryGirl.create(:partner) }
    before { FactoryGirl.create(:user_partner, user: user, partner: partner, default: false) }

    before { delete :destroy, {id: partner.to_param, user_id: user.id, token: user.token } }

    it { expect(user.user_partners).to eq([]) }
  end
end