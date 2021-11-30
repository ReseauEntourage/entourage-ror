require 'rails_helper'

RSpec.describe Api::V1::PartnersController, type: :controller do
  let!(:user) { FactoryBot.create :pro_user }

  describe 'GET index' do
    let!(:partner1) { FactoryBot.create(:partner, name: "Partner B") }
    let!(:partner2) { FactoryBot.create(:partner, name: "Partner A", postal_code: "75008") }
    # before { FactoryBot.create(:user_partner, user: user, partner: partner1) }

    before { get 'index', params: { token: user.token } }
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

  describe 'GET show' do
    let!(:partner1) { FactoryBot.create(:partner, name: "Partner A", postal_code: "75008") }
    let!(:following) { nil }

    before { get 'show', params: { id: partner1.id, token: user.token } }
    # TODO(partner)
    it { expect(JSON.parse(response.body)).to eq(
      "partner" => {
        "id" => partner1.id,
        "name" => "Partner A",
        "large_logo_url" => "MyString",
        "small_logo_url" => "https://s3-eu-west-1.amazonaws.com/entourage-ressources/check-small.png",
        "description" => "MyDescription",
        "donations_needs" => nil,
        "volunteers_needs" => nil,
        "phone" => nil,
        "address" => "174 rue Championnet, Paris",
        "website_url" => nil,
        "email" => nil,
        "default" => true,
        "following" => false
      }
    )}

    context "followed" do
      let!(:following) { create :following, user: user, partner: partner1 }
      it { expect(JSON.parse(response.body)).to match(
        "partner" => hash_including(
          "following" => true
        )
      )}
    end
  end

  describe 'POST join_request' do
    before { post :join_request, params: {token: user.token, postal_code: "75008", partner_role_title: "Senior VP of Meme Warfare"}.merge(params) }
    let(:join_request) { user.partner_join_requests.last }

    describe 'new partner' do
      let(:params) { {new_partner_name: "New"} }
      it { expect(response.status).to eq 200 }
      it { expect(join_request.attributes).to include(
        "user_id"=>user.id,
        "partner_id"=>nil,
        "new_partner_name"=>"New",
        "postal_code"=>"75008",
        "partner_role_title"=>"Senior VP of Meme Warfare"
      )}
    end

    describe 'existing partner' do
      let(:params) { {partner_id: 42} }
      it { expect(response.status).to eq 200 }
      it { expect(join_request.attributes).to include(
        "user_id"=>user.id,
        "partner_id"=>42,
        "new_partner_name"=>nil,
        "postal_code"=>"75008",
        "partner_role_title"=>"Senior VP of Meme Warfare"
      )}
    end

    describe 'both parameters' do
      let(:params) { {partner_id: 42, new_partner_name: "New"} }
      it { expect(response.status).to eq 400 }
      it { expect(JSON.parse(response.body)).to eq(
        "error" => {
          "code" => "INVALID_PARTNER_JOIN_REQUEST",
          "message" => ["Partner 'new_partner_name' must be nil when 'partner_id' is present"]
        }
      )}
    end

    describe 'neither parameters' do
      let(:params) { {} }
      it { expect(response.status).to eq 400 }
      it { expect(JSON.parse(response.body)).to eq(
        "error" => {
          "code" => "INVALID_PARTNER_JOIN_REQUEST",
          "message" => ["Partner 'partner_id' or 'new_partner_name' must be present"]
        }
      )}
    end
  end
end
