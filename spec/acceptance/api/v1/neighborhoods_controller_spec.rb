require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::NeighborhoodsController do
  explanation "Neighborhoods"
  header "Content-Type", "application/json"

  post 'api/v1/neighborhoods' do
    route_summary "Creates a neighborhood"

    parameter :token, type: :string, required: true

    with_options :scope => :neighborhood, :required => true do
      parameter :name, "Name"
      parameter :ethics, "Ethics", required: false
      parameter :latitude, "Latitude"
      parameter :longitude, "Longitude"
      parameter :interests, "Interests", required: false
      parameter :image_url, "Photo url", required: false
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
end
