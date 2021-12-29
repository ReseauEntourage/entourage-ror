require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::TourPointsController do
  explanation "TourPoints"
  header "Content-Type", "application/json"

  post '/api/v1/tours/:tour_id/tour_points' do
    route_summary "Create tour points"

    parameter :token, type: :string, required: true
    parameter :tour_id, type: :integer, required: true

    with_options :scope => :tour_points, :required => true do
      parameter :latitude, "Latitude", type: :number
      parameter :longitude, "Longitude", type: :number
      parameter :passing_time, "Time passed for an encounter", type: :number
    end

    let(:user) { FactoryBot.create :pro_user }
    let(:tour_id) { FactoryBot.create(:tour).id }
    let(:tour_point) { FactoryBot.build :tour_point }

    let(:raw_post) { {
      token: user.token,
      format: :json,
      tour_points: [{
        latitude: tour_point.latitude,
        longitude: tour_point.longitude,
        passing_time: tour_point.passing_time.iso8601(3)
      }]
    }.to_json }

    context '201' do
      example_request 'Create tour points' do
        expect(response_status).to eq(201)
        expect(JSON.parse(response_body)).to have_key('status')
      end
    end
  end
end
