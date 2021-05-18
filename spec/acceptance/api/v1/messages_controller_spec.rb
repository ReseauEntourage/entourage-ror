require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::MessagesController do
  explanation "Messages"
  header "Content-Type", "application/json"

  post 'api/v1/messages' do
    route_summary "Creates a message"

    parameter :token, type: :string, required: true

    with_options :scope => :message, :required => true do
      parameter :content
      parameter :first_name
      parameter :last_name
      parameter :email
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
      example_request 'Create message' do
        expect(status).to eq(201)
        expect(JSON.parse(response_body)).to have_key('id')
      end
    end
  end
end
