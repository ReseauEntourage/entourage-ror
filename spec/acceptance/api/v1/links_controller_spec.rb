require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::LinksController do
  explanation 'Deeplinks'
  header 'Content-Type', 'application/json'

  get '/api/v1/links/:id/redirect' do
    route_summary 'Gets a deeplink redirect'

    parameter :id, 'see app/controller/api/v1/links_controller for full list'
    parameter :token, 'Required except for some parameter id. See same file', type: :string

    let(:user) { FactoryBot.create(:public_user) }

    context 'with required token' do
      let(:id) { 'devenir-ambassadeur' }
      let(:token) { user.token }

      example_request 'Get redirection with required token' do
        expect(response_status).to eq(302)
      end
    end

    context 'without required token' do
      let(:id) { 'terms' }

      example_request 'Get redirection without required token' do
        expect(response_status).to eq(302)
      end
    end
  end
end
