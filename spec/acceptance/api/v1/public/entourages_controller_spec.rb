require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::Public::EntouragesController do
  explanation 'Users'
  header 'Content-Type', 'application/json'

  get '/api/v1/public/entourages/:uuid' do
    route_summary 'Get entourage'
    # route_description "no description"

    parameter :token, type: :string, required: true
    parameter :uuid, type: :string, required: true

    let(:user) { FactoryBot.create(:public_user) }
    let(:token) { user.token }
    let(:entourage) { FactoryBot.create(:entourage) }
    let(:uuid) { identifier }

    context 'uuid' do
      let(:identifier) { entourage.uuid }

      example_request 'Get entourage with uuid' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('entourage')
      end
    end

    context 'uuid_v2' do
      let(:identifier) { entourage.uuid_v2 }

      example_request 'Get entourage with uuid_v2' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('entourage')
      end
    end

    context 'id' do
      let(:identifier) { entourage.id }

      example_request 'Get entourage with id' do
        expect(response_status).to eq(404)
        expect(JSON.parse(response_body)).to have_key('message')
      end
    end
  end
end
