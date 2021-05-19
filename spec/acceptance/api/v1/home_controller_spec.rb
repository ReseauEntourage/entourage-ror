require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::HomeController do
  explanation "Home"
  header "Content-Type", "application/json"

  get '/api/v1/home' do
    parameter :token, type: :string, required: true
    parameter :latitude, type: :number, required: true
    parameter :longitude, type: :number, required: true

    let(:user) { FactoryGirl.create(:offer_help_user) }
    let(:token) { user.token }
    let(:latitude) { 48.854367553784954 }
    let(:longitude) { 2.270340589096274 }

    let!(:entourage) { FactoryGirl.create(:entourage, :joined, user: user, status: "open", latitude: 48.85436, longitude: 2.270340) }
    let!(:outing) { FactoryGirl.create(:outing) }
    let!(:announcement) { FactoryGirl.create(:announcement, user_goals: [:offer_help], areas: [:sans_zone]) }
    let!(:announcement_ask) { FactoryGirl.create(:announcement, user_goals: [:ask_for_help], areas: [:sans_zone], id: 2) }
    let!(:tour) { FactoryGirl.create(:tour) }

    context '200' do
      example_request 'Get home' do
        expect(status).to eq(200)
      end
    end
  end
end
