require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::MessagesController do
  explanation "Messages"
  header "Content-Type", "application/json"

  post 'api/v1/messages' do
    route_summary "Sends a message to Entourage team"

    parameter :token, type: :string, required: true

    with_options scope: :message do
      parameter :content, required: true
      parameter :first_name, "First name", required: false
      parameter :last_name, "Last name", required: false
      parameter :email, "Email", required: false
    end

    let(:user) { FactoryBot.create(:pro_user) }

    let(:raw_post) { {
      token: user.token,
      message: {
        content: "content",
        first_name: "first_name",
        last_name: "last_name",
        email: "some@email.com",
      }
    }.to_json }

    context '201' do
      example_request 'Sends a message to Entourage team' do
        expect(response_status).to eq(201)
        expect(JSON.parse(response_body)).to have_key('id')
      end
    end
  end
end
