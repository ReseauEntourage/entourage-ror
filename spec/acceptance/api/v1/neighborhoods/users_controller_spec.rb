require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::Neighborhoods::UsersController do
  explanation "Users"
  header "Content-Type", "application/json"

  get '/api/v1/neighborhoods/:neighborhood_id/users' do
    route_summary "Get neighborhood members"

    parameter :token, type: :string, required: true
    parameter :neighborhood_id, type: :integer, required: true

    let(:user) { FactoryBot.create(:public_user) }
    let(:member) { FactoryBot.create(:public_user) }
    let(:token) { user.token }
    let(:neighborhood) { FactoryBot.create(:neighborhood) }
    let(:neighborhood_id) { neighborhood.id }
    let!(:join_request) { create(:join_request, user: member, joinable: neighborhood, status: :accepted) }

    context '200' do
      let!(:join_request) { create(:join_request, user: user, joinable: neighborhood, status: :accepted) }

      example_request 'Get neighborhood members' do
        expect(response_status).to eq(200)
      end
    end
  end

  post '/api/v1/neighborhoods/:neighborhood_id/users' do
    route_summary "Join neighborhood"

    parameter :token, type: :string, required: true
    parameter :neighborhood_id, type: :integer, required: true
    parameter :distance, type: :number

    let(:user) { FactoryBot.create(:pro_user) }
    let(:neighborhood) { FactoryBot.create(:neighborhood) }
    let(:neighborhood_id) { neighborhood.id }

    let(:raw_post) { {
      token: user.token,
      distance: 10.0,
    }.to_json }

    context '201' do
      example_request 'Join neighborhood' do
        expect(response_status).to eq(201)
        expect(JSON.parse(response_body)).to have_key('user')
      end
    end
  end
end
