require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::Tours::UsersController do
  explanation "Users"
  header "Content-Type", "application/json"

  get '/api/v1/tours/:tour_id/users' do
    route_summary "Get users"
    # route_description "no description"

    parameter :token, type: :string, required: true
    parameter :tour_id, type: :integer, required: true

    let(:user) { FactoryBot.create(:public_user) }
    let(:token) { user.token }
    let(:tour) { FactoryBot.create(:tour) }
    let(:tour_id) { tour.id }

    context '200' do
      let!(:join_request) { FactoryBot.create(:join_request, joinable: tour, user: user, status: :accepted) }

      example_request 'Get users' do
        expect(response_status).to eq(200)
      end
    end
  end

  post '/api/v1/tours/:tour_id/users' do
    route_summary "Request user to join tour"
    # route_description "no description"

    parameter :token, type: :string, required: true
    parameter :tour_id, type: :integer, required: true
    parameter :distance, type: :number

    let(:user) { FactoryBot.create(:pro_user) }
    let(:tour) { FactoryBot.create(:tour) }
    let(:tour_id) { tour.id }

    let(:raw_post) { {
      token: user.token,
      distance: 10.0,
    }.to_json }

    context '201' do
      example_request 'Request user to join tour' do
        expect(response_status).to eq(201)
        expect(JSON.parse(response_body)).to have_key('user')
      end
    end
  end

  patch '/api/v1/tours/:tour_id/users/:id' do
    route_summary "Update user joined status (deprecated)"
    # route_description "no description"

    parameter :token, type: :string, required: true
    parameter :tour_id, type: :integer, required: true
    parameter :id, "User id", type: :integer

    with_options :scope => :user, :required => true do
      parameter :status, type: :string
    end

    let(:user) { FactoryBot.create(:pro_user) }
    let(:id) { user.id }
    let(:tour) { FactoryBot.create(:tour) }
    let(:tour_id) { tour.id }

    let(:raw_post) { {
      token: user.token,
      user: { status: :accepted }
    }.to_json }

    context '204' do
      let!(:join_request) { create(:join_request, user: user, joinable: tour, status: "accepted") }
      let(:requester) { FactoryBot.create(:pro_user) }
      let!(:requester_join_request) { create(:join_request, user: requester, joinable: tour, status: "pending") }

      example_request 'Update user joined status (deprecated)' do
        expect(response_status).to eq(204)
        expect(response_body).to eq('')
      end
    end
  end

  delete '/api/v1/tours/:tour_id/users/:id' do
    route_summary "Delete user joined status"
    # route_description "no description"

    parameter :token, type: :string, required: true
    parameter :tour_id, type: :integer, required: true
    parameter :id, "User id", type: :integer

    let(:user) { FactoryBot.create(:pro_user) }
    let(:id) { user.id }
    let(:tour) { FactoryBot.create(:tour) }
    let(:tour_id) { tour.id }

    let(:raw_post) { {
      token: user.token
    }.to_json }

    context '200' do
      let!(:other_user) { FactoryBot.create(:pro_user) }
      let!(:other_join_request) { create(:join_request, user: other_user, joinable: tour, status: :accepted) }
      let!(:my_join_request) { create(:join_request, user: user, joinable: tour, status: :accepted) }

      example_request 'Delete user joined status' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('user')
      end
    end
  end
end
