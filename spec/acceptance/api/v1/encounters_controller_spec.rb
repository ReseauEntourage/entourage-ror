require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::EncountersController do
  explanation "Encounters"
  header "Content-Type", "application/json"

  post '/api/v1/tours/:tour_id/encounters' do
    route_summary "Allows to create encounters"
    # route_description "no description"

    parameter :token, "User token", type: :string, required: true
    parameter :tour_id, "Tour id", type: :integer, required: true

    with_options :scope => :encounter, :required => true do
      parameter :street_person_name
      parameter :date
      parameter :latitude
      parameter :longitude
      parameter :message, required: false
      parameter :voice_message, "Voice message URL", required: false
    end

    let(:user) { FactoryBot.create(:pro_user) }
    let(:token) { user.token }
    let(:tour) { FactoryBot.create :tour, user: user }
    let(:tour_id) { tour.id }

    let(:raw_post) { {
      token: user.token,
      tour_id: tour.id,
      encounter: {
        street_person_name: "John Doe",
        date: "2021-01-01 00:00:00",
        latitude: 48.870424,
        longitude: 2.306820
      }
    }.to_json }

    context '201' do
      example_request 'Create encounter with no message' do
        expect(response_status).to eq(201)
        expect(JSON.parse(response_body)).to have_key('encounter')
      end
    end
  end
end
