require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::QuestionsController do
  explanation "Questions"
  header "Content-Type", "application/json"

  get '/api/v1/questions' do
    route_summary "Get questions"

    parameter :token, type: :string, required: true

    let(:user) { FactoryBot.create(:pro_user) }
    let(:token) { user.token }

    let!(:question) { FactoryBot.create(:question, organization: user.organization) }

    context '200' do
      example_request 'Get questions' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('questions')
      end
    end
  end
end
