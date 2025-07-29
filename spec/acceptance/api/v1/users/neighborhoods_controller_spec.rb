require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::Users::NeighborhoodsController do
  explanation 'Neighborhoods'
  header 'Content-Type', 'application/json'

  get '/api/v1/users/:user_id/neighborhoods' do
    route_summary 'Find neighborhoods a user has joined'
    # route_description "no description"

    parameter :token, type: :string, required: true
    parameter :user_id, type: :integer, required: true
    parameter :page, type: :integer, default: 1
    parameter :per, type: :integer, default: 25

    let(:user) { FactoryBot.create(:public_user) }
    let(:user_id) { FactoryBot.create(:public_user).id }
    let!(:neighborhood) { FactoryBot.create(:neighborhood, user_id: user_id) }
    let(:token) { user.token }

    context '200' do
      example_request 'Get neighborhoods' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('neighborhoods')
      end
    end
  end
end
