require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::EncountersController do
  explanation "Encounters"
  header "Content-Type", "application/json"

  get '/api/v1/tours/:tour_id/encounters' do
    route_summary "Gets all encounters from a tour"
    # route_description "no description"

    parameter :token, "User token", type: :string, required: true
    parameter :tour_id, "Tour id", type: :integer, required: true

    let(:user) { FactoryBot.create(:pro_user) }
    let(:token) { user.token }
    let(:tour) { FactoryBot.create :tour, user: user }
    let(:tour_id) { tour.id }
    let!(:encounter) { FactoryBot.create(:encounter, tour: tour) }

    context '200' do
      example_request 'Get encounters' do
        expect(response_status).to eq(201)
        expect(JSON.parse(response_body)).to have_key('encounters')
      end
    end
  end

  post '/api/v1/tours/:tour_id/encounters' do
    route_summary "Create an encounter during a tour"
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

  patch '/api/v1/encounters/:id' do
    route_summary "Updates an encounter"
    # route_description "no description"

    parameter :token, "User token", type: :string, required: true
    parameter :id, "Encounter id", type: :integer, required: true

    with_options :scope => :encounter, :required => true do
      parameter :street_person_name
      parameter :date
      parameter :latitude
      parameter :longitude
      parameter :message, required: false
      parameter :voice_message, "Voice message URL", required: false
    end

    let(:user) { FactoryBot.create(:pro_user) }
    let!(:encounter) { FactoryBot.create(:encounter) }

    let(:id) { encounter.id }
    let(:raw_post) { {
      token: user.token,
      encounter: {
        street_person_name: "foo"
      }
    }.to_json }

    context '200' do
      example_request 'Update encounter' do
        expect(response_status).to eq(204)
        expect(response_body).to eq("")
      end
    end
  end
end
