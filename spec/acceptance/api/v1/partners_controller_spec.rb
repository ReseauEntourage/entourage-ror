require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::PartnersController do
  explanation 'Partners'
  header 'Content-Type', 'application/json'

  get '/api/v1/partners' do
    route_summary 'Allows users to find partners'
    # route_description "no description"

    parameter :token, 'User token', type: :string, required: true

    let(:user) { FactoryBot.create(:public_user) }
    let!(:partner) { FactoryBot.create(:partner) }
    let(:token) { user.token }

    context '200' do
      example_request 'Get partners' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('partners')
      end
    end
  end

  get '/api/v1/partners/:id' do
    route_summary 'Allows users to find a given partner'
    # route_description "no description"

    parameter :token, 'User token', type: :string, required: true

    let(:user) { FactoryBot.create(:public_user) }
    let!(:partner) { FactoryBot.create(:partner) }
    let(:token) { user.token }
    let(:id) { partner.id }

    context '200' do
      example_request 'Get partner' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('partner')
      end
    end
  end

  post '/api/v1/partners/join_request' do
    route_summary 'Allows users to request to join a partner'
    # route_description "no description"

    parameter :token, 'User token', type: :string, required: true
    parameter :partner_id, "Partner id; 'partner_id' or 'new_partner_name' must be present", type: :integer, required: false
    parameter :new_partner_name, "New partner name; 'new_partner_name' must be nil when 'partner_id' is present", type: :string, required: false
    parameter :postal_code, 'Postal code', type: :string, required: true
    parameter :partner_role_title, 'Partner role title', type: :string, required: true

    let(:user) { FactoryBot.create(:public_user) }
    let!(:partner) { FactoryBot.create(:partner) }

    let(:raw_post) { {
      token: user.token,
      partner_id: partner.id,
      new_partner_name: nil,
      postal_code: '44240',
      partner_role_title: 'Partner role title'
    }.to_json }

    context '200' do
      example_request 'Request to join a partner' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to eq({})
      end
    end
  end
end
