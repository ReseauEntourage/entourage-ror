require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::TourAreasController do
  explanation "Tour areas"
  header "Content-Type", "application/json"

  get '/api/v1/tour_areas' do
    parameter :token, type: :string, required: true

    let(:user) { FactoryBot.create(:public_user) }
    let(:token) { user.token }
    let!(:tour_area_list) { FactoryBot.create_list(:tour_area, 2) }

    context '200' do
      example_request 'Get tour_areas' do
        expect(response_status).to eq(200)
      end
    end
  end

  get '/api/v1/tour_areas/:id' do
    parameter :id, type: :integer, required: true
    parameter :token, type: :string, required: true

    let(:user) { FactoryBot.create(:public_user) }
    let(:token) { user.token }
    let(:tour_area) { FactoryBot.create(:tour_area) }
    let(:id) { tour_area.id }

    context '200' do
      example_request 'Show tour_area' do
        expect(response_status).to eq(200)
      end
    end
  end

  post '/api/v1/tour_areas/:id/request' do
    parameter :id, "Tour area id", type: :integer, required: true
    parameter :token, type: :string, required: true
    parameter :message, type: :string

    let(:user) { FactoryBot.create(:public_user) }
    let(:tour_area) { FactoryBot.create(:tour_area) }

    let(:id) { tour_area.id }
    let(:raw_post) { {
      token: user.token,
      message: 'foo'
    }.to_json }

    context '200' do
      example_request 'Request information about tours' do
        expect(response_status).to eq(200)
      end
    end
  end
end
