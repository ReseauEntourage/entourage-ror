require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::TourAreasController do
  explanation "api/v1/tour_areas"
  header "Content-Type", "application/json"

  get '/api/v1/tour_areas' do
    parameter :token, type: :string

    let(:user) { FactoryGirl.create(:offer_help_user) }
    let(:token) { user.token }
    let!(:tour_area_list) { FactoryGirl.create_list(:tour_area, 2) }

    context '200' do
      example_request 'Getting tour_areas' do
        expect(status).to eq(200)
      end
    end
  end

  get '/api/v1/tour_areas/:id' do
    parameter :id, type: :integer
    parameter :token, type: :string

    let(:user) { FactoryGirl.create(:offer_help_user) }
    let(:token) { user.token }
    let(:tour_area) { FactoryGirl.create(:tour_area) }
    let(:id) { tour_area.id }

    context '200' do
      example_request 'Show tour_area' do
        expect(status).to eq(200)
      end
    end
  end
end
