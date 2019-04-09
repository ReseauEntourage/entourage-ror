require 'rails_helper'

RSpec.describe Api::V1::PartnersController, type: :controller do

  let!(:user) { FactoryGirl.create :pro_user }

  describe 'GET index' do
    let!(:partner1) { FactoryGirl.create(:partner) }
    let!(:partner2) { FactoryGirl.create(:partner) }
    # before { FactoryGirl.create(:user_partner, user: user, partner: partner1) }

    before { get 'index', token: user.token }
    # TODO(partner)
    it { expect(JSON.parse(response.body)).to eq({"partners"=>[]}) }
  end
end
