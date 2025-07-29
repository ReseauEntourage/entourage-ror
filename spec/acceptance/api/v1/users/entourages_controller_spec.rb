require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::Users::EntouragesController do
  explanation 'Entourages'
  header 'Content-Type', 'application/json'

  get '/api/v1/users/:user_id/entourages' do
    route_summary 'Find entourages a user has joined'
    # route_description "no description"

    parameter :token, type: :string, required: true
    parameter :user_id, type: :integer, required: true
    parameter :page, type: :integer, default: 1
    parameter :per, type: :integer, default: 25
    parameter :latitude, 'Latitude', type: :number
    parameter :longitude, 'Longitude', type: :number
    parameter :distance, 'Distance from GPS coordinates from which Entourage should be found (km)', type: :number
    parameter :status, 'open, closed, full, suspended, blacklisted', type: :string, default: :all

    let(:user) { FactoryBot.create(:public_user) }
    let(:user_id) { FactoryBot.create(:public_user).id }
    let!(:entourage) { FactoryBot.create(:entourage, :joined, user_id: user_id, status: 'open') }
    let(:token) { user.token }

    context '200' do
      example_request 'Get entourages' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('entourages')
      end
    end
  end
end
