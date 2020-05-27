require 'rails_helper'

RSpec.describe Api::V1::PartnersController, type: :controller do

  let!(:user) { FactoryGirl.create :pro_user }

  describe 'GET index' do
    let!(:partner1) { FactoryGirl.create(:partner, name: "Partner B") }
    let!(:partner2) { FactoryGirl.create(:partner, name: "Partner A", postal_code: "75008") }
    # before { FactoryGirl.create(:user_partner, user: user, partner: partner1) }

    before { get 'index', token: user.token }
    # TODO(partner)
    it { expect(JSON.parse(response.body)).to eq(
      {"partners"=>[
        {
          "id"=>partner2.id,
          "name"=>"Partner A",
          "postal_code"=>"75008"
        },
        {
          "id"=>partner1.id,
          "name"=>"Partner B",
          "postal_code"=>nil
        }
      ]}
    )}
  end
end
