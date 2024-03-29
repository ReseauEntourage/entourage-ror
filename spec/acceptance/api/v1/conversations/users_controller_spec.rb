require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::Conversations::UsersController do
  explanation "Users"
  header "Content-Type", "application/json"

  delete '/api/v1/conversations/:conversation_id/users' do
    route_summary "Delete user joined status"
    # route_description "no description"

    parameter :token, type: :string, required: true
    parameter :conversation_id, type: :integer, required: true

    let(:user) { FactoryBot.create(:pro_user) }
    let(:conversation_id) { conversation.id }
    let!(:join_request) { create(:join_request, user: user, joinable: conversation, status: :accepted) }

    let(:raw_post) { {
      token: user.token
    }.to_json }

    context '200' do
      let(:conversation) { FactoryBot.create(:entourage) }

      example_request 'Delete user from action' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('user')
        expect(join_request.reload.status).to eq('cancelled')
      end
    end
  end
end
