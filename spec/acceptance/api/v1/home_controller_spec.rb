require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::HomeController do
  explanation "api/v1/home"
  header "Content-Type", "application/json"

  get '/api/v1/home' do
    parameter :token, type: :string

    let(:user) { FactoryGirl.create(:offer_help_user) }
    let(:token) { user.token }

    context '200' do
      example_request 'Getting home' do
        expect(status).to eq(200)
      end
    end
  end
end
