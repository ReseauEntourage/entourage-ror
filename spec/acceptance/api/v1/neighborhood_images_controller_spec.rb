require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::NeighborhoodImagesController do
  explanation 'Galerie de photos de groupes de voisinage'
  header 'Content-Type', 'application/json'

  get '/api/v1/neighborhood_images' do
    route_summary 'Get neighborhood images'
    # route_description "no description"

    parameter :token, 'User token', type: :string, required: true
    let!(:neighborhood_image) { create :neighborhood_image, image_url: 'path-to-img.jpeg' }
    let(:user) { FactoryBot.create(:public_user) }
    let(:token) { user.token }

    context '200' do
      example_request 'Get neighborhood images' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('neighborhood_images')
      end
    end
  end

  get 'api/v1/neighborhood_images/:id' do
    route_summary 'Get a neighborhood image'

    parameter :id, required: true
    parameter :token, type: :string, required: true

    let(:neighborhood_image) { create :neighborhood_image, image_url: 'path-to-img.jpeg' }
    let(:id) { neighborhood_image.id }
    let(:user) { FactoryBot.create(:public_user) }
    let(:token) { user.token }

    context '200' do
      example_request 'Get a neighborhood image' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('neighborhood_image')
      end
    end
  end
end
