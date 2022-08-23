require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::Conversations::ChatMessagesController do
  explanation "Chat messages"
  header "Content-Type", "application/json"

  get '/api/v1/conversations/:conversation_id/chat_messages' do
    route_summary "Find user chat_messages in a conversation"
    # route_description "no description"

    parameter :token, type: :string, required: true
    parameter :conversation_id, type: :integer, required: true

    let(:user) { FactoryBot.create(:public_user) }
    let(:token) { user.token }
    let(:conversation) { FactoryBot.create(:conversation) }
    let(:conversation_id) { conversation.id }
    let!(:chat_message) { FactoryBot.create(:chat_message, messageable: conversation) }

    context '200' do
      let!(:join_request) { FactoryBot.create(:join_request, joinable: conversation, user: user, status: :accepted) }

      example_request 'Get chat_messages' do
        expect(response_status).to eq(200)
      end
    end

    context '200' do
      example_request 'Non members can see chat_messages' do
        expect(response_status).to eq(200)
      end
    end
  end
end
