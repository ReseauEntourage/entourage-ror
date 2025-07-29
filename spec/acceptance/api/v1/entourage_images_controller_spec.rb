require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::EntourageImagesController do
  explanation "Galerie de photos d'événements"
  header 'Content-Type', 'application/json'

  get '/api/v1/entourage_images' do
    route_summary 'Allows users to find entourage images'
    # route_description "no description"

    parameter :token, 'User token', type: :string, required: true
    let!(:entourage_image) { create :entourage_image, landscape_url: 'path-to-img.jpeg' }
    let(:user) { FactoryBot.create(:public_user) }
    let(:token) { user.token }

    context '200' do
      example_request 'Get entourage images' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('entourage_images')
      end
    end
  end

  get 'api/v1/entourage_images/:id' do
    route_summary 'Get an entourage'

    parameter :id, required: true
    parameter :token, type: :string, required: true

    let(:entourage_image) { create :entourage_image, landscape_url: 'path-to-img.jpeg' }
    let(:id) { entourage_image.id }
    let(:user) { FactoryBot.create(:public_user) }
    let(:token) { user.token }

    context '200' do
      example_request 'Get entourage image' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('entourage_image')
      end
    end
  end
end
