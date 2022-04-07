require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::NeighborhoodsController do
  explanation "Neighborhoods"
  header "Content-Type", "application/json"

  get '/api/v1/neighborhoods' do
    route_summary "Find neighborhoods"

    parameter :token, "User token", type: :string, required: true

    let(:user) { FactoryBot.create(:pro_user) }
    let!(:neighborhood) { FactoryBot.create(:neighborhood) }
    let(:token) { user.token }

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
      parameter :ethics, "Ethics", required: false
      parameter :latitude, "Latitude"
      parameter :longitude, "Longitude"
      parameter :interests, "Interests", required: false
      parameter :image_url, "Image url", required: false
    end

    let(:neighborhood) { build :neighborhood }
    let(:user) { FactoryBot.create(:pro_user) }

    let(:raw_post) { {
      token: user.token,
      neighborhood: {
        name: neighborhood.name,
        ethics: neighborhood.ethics,
        latitude: neighborhood.latitude,
        longitude: neighborhood.longitude,
        interests: neighborhood.interest_list,
        image_url: neighborhood.image_url
      }
    }.to_json }

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
end
