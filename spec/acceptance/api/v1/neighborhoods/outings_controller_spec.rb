require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::Neighborhoods::OutingsController do
  explanation "Outings"
  header "Content-Type", "application/json"

  post '/api/v1/neighborhoods/:neighborhood_id/outings' do
    route_summary "Create outings"
    # route_description "no description"

    parameter :token, type: :string, required: true
    parameter :neighborhood_id, type: :integer, required: true

    with_options scope: :outing, required: false do
      parameter :title, required: true
      parameter :description, "Description", type: :string
      parameter :event_url, "Event url", type: :string
      parameter :latitude, "Latitude", type: :string, required: true
      parameter :longitude, "Longitude", type: :string, required: true
      parameter :entourage_image_id, "Entourage image id", type: :integer
      parameter :metadata, "Metadata", required: false
      with_options scope: "outing[metadata]", required: true do
        parameter :starts_at, "Start time"
        parameter :ends_at, "End time"
        parameter :place_name, "Place name"
        parameter :street_address, "Street address"
        parameter :google_place_id, "Google place ID"
      end
    end

    let(:user) { FactoryBot.create(:pro_user) }
    let(:neighborhood) { FactoryBot.create(:neighborhood) }
    let(:neighborhood_id) { neighborhood.id }
    let(:entourage_image) { FactoryBot.create(:entourage_image) }

    let(:outing) { build :outing }

    let(:raw_post) { {
      token: user.token,
      outing: {
        title: 'Groupe de voisins',
        latitude: outing.latitude,
        longitude: outing.longitude,
        entourage_image_id: entourage_image.id,
        metadata: {
          starts_at: outing.metadata[:starts_at],
          ends_at: outing.metadata[:ends_at],
          place_name: outing.metadata[:place_name],
          street_address: outing.metadata[:street_address],
          google_place_id: outing.metadata[:google_place_id],
        }
      }
    }.to_json }

    context '201' do
      let!(:join_request) { FactoryBot.create(:join_request, joinable: neighborhood, user: user, status: :accepted) }

      context 'Simple outing' do
        example_request 'Create outing' do
          expect(response_status).to eq(201)
          expect(JSON.parse(response_body)).to have_key('outing')
        end
      end

      context 'outing as a comment of another outing' do
        let!(:parent_id) { outing.id }

        example_request 'Create outing as a comment of another outing' do
          expect(response_status).to eq(201)
          expect(JSON.parse(response_body)).to have_key('outing')
        end
      end
    end

    context '401' do
      example_request 'Cannot create outings if the user does not belong to the neighborhood' do
        expect(response_status).to eq(401)
      end
    end
  end
end
