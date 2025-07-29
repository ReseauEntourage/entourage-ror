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

  post '/api/v1/conversations/:conversation_id/chat_messages' do
    route_summary "Create chat_messages"
    # route_description "no description"

    parameter :token, type: :string, required: true
    parameter :conversation_id, type: :integer, required: true

    with_options scope: :chat_message, required: true do
      parameter :content, type: :string
    end

    let(:user) { FactoryBot.create(:pro_user) }
    let(:conversation) { FactoryBot.create(:conversation) }
    let(:conversation_id) { conversation.id }
    let(:chat_message) { FactoryBot.create(:chat_message, messageable: conversation) }

    let(:raw_post) { {
      token: user.token,
      chat_message: {
        content: "foo"
      }
    }.to_json }

    context '201' do
      let!(:join_request) { FactoryBot.create(:join_request, joinable: conversation, user: user, status: :accepted) }

      example_request 'Create chat_message' do
        expect(response_status).to eq(201)
        expect(JSON.parse(response_body)).to have_key('chat_message')
      end
    end

    context '401' do
      example_request 'Cannot create chat_messages if the user does not belong to the conversation' do
        expect(response_status).to eq(401)
      end
    end
  end
end
