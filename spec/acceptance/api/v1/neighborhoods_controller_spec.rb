require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::NeighborhoodsController do
  explanation "Neighborhoods"
  header "Content-Type", "application/json"

  get '/api/v1/neighborhoods' do
    route_summary "Find neighborhoods"

    parameter :token, "User token", type: :string, required: true
    parameter :q, "Search text", type: :string, required: false

    let(:user) { FactoryBot.create(:pro_user) }
    let!(:neighborhood) { FactoryBot.create(:neighborhood, name: "foobar") }
    let(:token) { user.token }
    let(:q) { :foo }

    context '200' do
      example_request 'Get neighborhoods' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('neighborhoods')
      end
    end
  end

  get 'api/v1/neighborhoods/:id' do
    route_summary "Get a neighborhood"

    parameter :id, required: true
    parameter :token, type: :string, required: true

    let(:neighborhood) { create :neighborhood }
    let(:id) { neighborhood.id }
    let(:user) { FactoryBot.create(:pro_user) }
    let(:token) { user.token }

    context '200' do
      example_request 'Get neighborhood' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('neighborhood')
      end
    end
  end

  post 'api/v1/neighborhoods' do
    route_summary "Creates a neighborhood"

    parameter :token, type: :string, required: true

    with_options :scope => :neighborhood, :required => true do
      parameter :name, "Name"
      parameter :description, "Description"
      parameter :welcome_message, "Welcome message", required: false
      parameter :ethics, "Ethics", required: false
      parameter :latitude, "Latitude"
      parameter :longitude, "Longitude"
      parameter :interests, "Interests", required: false
      parameter :other_interest, "Other interest", required: false
      parameter :neighborhood_image_id, "Neighborhood image id", required: false
      parameter :google_place_id, "Google place id", required: false
    end

    let(:neighborhood) { build :neighborhood }
    let(:neighborhood_image) { FactoryBot.create :neighborhood_image }
    let(:user) { FactoryBot.create(:pro_user) }

    let(:raw_post) { {
      token: user.token,
      neighborhood: {
        name: neighborhood.name,
        description: neighborhood.description,
        ethics: neighborhood.ethics,
        latitude: neighborhood.latitude,
        longitude: neighborhood.longitude,
        interests: neighborhood.interest_list,
        neighborhood_image_id: neighborhood_image.id,
        google_place_id: 'ChIJQWDurldu5kcRmj2mNTjxtxE'
      }
    }.to_json }

    before { UserServices::AddressService.stub(:get_google_place_details).and_return(
      {
        place_name: '174, rue Championnet',
        latitude: 48.86,
        longitude: 2.35,
        postal_code: '75017',
        country: 'FR',
        google_place_id: 'ChIJQWDurldu5kcRmj2mNTjxtxE',
      }
    )}

    context '201' do
      example_request 'Create neighborhood' do
        expect(response_status).to eq(201)
        expect(JSON.parse(response_body)).to have_key('neighborhood')
      end
    end
  end

  patch 'api/v1/neighborhoods/:id' do
    route_summary "Updates a neighborhood"

    parameter :id, required: true
    parameter :token, type: :string, required: true

    with_options :scope => :neighborhood, :required => true do
      parameter :name, "Name", required: false
      parameter :ethics, "Ethics", required: false
      parameter :latitude, "Latitude", required: false
      parameter :longitude, "Longitude", required: false
      parameter :interests, "Interests", required: false
      parameter :image_url, "Image url", required: false
    end

    let(:neighborhood) { FactoryBot.create(:neighborhood, user: user) }
    let(:user) { FactoryBot.create(:pro_user) }

    let(:id) { neighborhood.id }
    let(:raw_post) { {
      token: user.token,
      neighborhood: {
        name: "new name",
        ethics: "new ethics",
      }
    }.to_json }

    context '200' do
      example_request 'Update neighborhood' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('neighborhood')
      end
    end
  end

  post 'api/v1/neighborhoods/:id/report' do
    route_summary "Sends an alert about a neighborhood"

    parameter :id, required: true
    parameter :token, type: :string, required: true
    with_options :scope => :report, :required => true do
      parameter :signals, type: :array
      parameter :message, type: :string
    end

    let(:neighborhood) { create :neighborhood }
    let(:user) { FactoryBot.create(:public_user) }

    let(:id) { neighborhood.id }
    let(:raw_post) { {
      token: user.token,
      report: {
        signals: ['spam'],
        message: 'message'
      }
    }.to_json }

    context '201' do
      example_request 'Report neighborhood' do
        expect(response_status).to eq(201)
      end
    end
  end
end
