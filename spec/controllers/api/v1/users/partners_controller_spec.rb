require 'rails_helper'

RSpec.describe Api::V1::Users::PartnersController, type: :controller do

  let!(:user) { FactoryBot.create :pro_user }

  describe 'POST create' do
    pending
    let!(:partner) { FactoryBot.create(:partner) }
    before { post :create, params: { partner: { id: partner.to_param }, user_id: user.id, token: user.token } }

    # TODO(partner)
    # it { expect(user.partners).to eq([]) }
    # it { expect(user.default_partner).to eq(nil) }
  end

  describe 'PUT update' do
    let!(:partner) { FactoryBot.create(:partner) }

    describe "set default partner" do
      pending
      # before { FactoryBot.create(:user_partner, user: user, partner: partner, default: false) }

      before { put :update, params: { id: partner.to_param, partner: { default: true }, user_id: user.id, token: user.token } }

      # TODO(partner)
      # it { expect(user.user_partners.first.default).to be false}
    end

    describe "remove default partner" do
      pending
      # before { FactoryBot.create(:user_partner, user: user, partner: partner, default: true) }

      before { put :update, params: { id: partner.to_param, partner: { default: false }, user_id: user.id, token: user.token } }

      # TODO(partner)
      # it { expect(user.user_partners.first.default).to be true}
    end
  end

  describe 'DELETE destroy' do
    pending
    let!(:partner) { FactoryBot.create(:partner) }
    # before { FactoryBot.create(:user_partner, user: user, partner: partner, default: false) }

    before { delete :destroy, params: { id: partner.to_param, user_id: user.id, token: user.token } }

    # TODO(partner)
    # it { expect(user.partners).to eq([partner]) }
  end
end
