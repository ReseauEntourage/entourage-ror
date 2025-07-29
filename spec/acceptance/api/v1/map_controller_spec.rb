require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::MapController do
  explanation 'Pois map'
  header 'Content-Type', 'application/json'

  get '/api/v1/map' do
    route_summary 'Get pois with the corresponding categories'
    # route_description "no description"

    parameter :token, 'User token', type: :string, required: true
    parameter :limit, 'per', type: :integer, default: 45
    parameter :distance, 'Distance', type: :integer
    parameter :latitude, 'Latitude', type: :number
    parameter :longitude, 'Longitude', type: :number

    let!(:poi) { FactoryBot.create :poi }
    let(:user) { FactoryBot.create(:public_user) }
    let(:token) { user.token }

    context '200' do
      example_request 'Get pois and categories' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('pois')
        expect(JSON.parse(response_body)).to have_key('categories')
      end
    end
  end
end
