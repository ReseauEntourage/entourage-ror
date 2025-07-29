require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::AnonymousUsersController do
  explanation 'AnonymousUsers'
  header 'Content-Type', 'application/json'

  post '/api/v1/anonymous_users' do
    route_summary 'Create an anonymous user'
    # route_description "no description"

    let!(:user) { AnonymousUserService.create_user $server_community }

    context '201' do
      example_request 'Create an anonymous user' do
        expect(response_status).to eq(201)
        expect(JSON.parse(response_body)).to have_key('user')
      end
    end
  end
end
