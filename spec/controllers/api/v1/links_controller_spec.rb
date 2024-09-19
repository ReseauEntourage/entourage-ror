require 'rails_helper'

describe Api::V1::LinksController do
  let(:user) { FactoryBot.create(:offer_help_user) }

  describe 'GET redirect' do
    context "not signed in and wrong id" do
      before { get :redirect, params: { id: 'foo' } }
      it { expect(response.status).to eq(401) }
    end

    context "not signed in and correct id" do
      before { get :redirect, params: { id: 'terms' } }
      it { expect(response.status).to eq(302) }
    end

    context "signed in and wrong id" do
      before { get :redirect, params: { id: 'foo', token: user.token } }
      it { expect(response.status).to eq(404) }
    end

    context "signed in and correct id" do
      before { get :redirect, params: { id: 'terms', token: user.token } }
      it { expect(response.status).to eq(302) }
      it { should redirect_to 'https://www.entourage.social/cgu/' }
    end
  end

  describe 'GET mesure_impact' do
    context "not signed in" do
      before { get :mesure_impact, params: {} }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      before { get :mesure_impact, params: { token: user.token } }
      it { expect(response.status).to eq(302) }
      it { should redirect_to "https://entourage-asso.typeform.com/to/w1OHXk1E#email=#{user.email}&phone=#{user.phone}" }
    end
  end
end
