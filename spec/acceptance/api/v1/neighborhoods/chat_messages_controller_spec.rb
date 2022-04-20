require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::Neighborhoods::ChatMessagesController do
  explanation "Chat messages"
  header "Content-Type", "application/json"

  get '/api/v1/neighborhoods/:neighborhood_id/chat_messages' do
    route_summary "Find user chat_messages in a neighborhood"
    # route_description "no description"

    parameter :token, type: :string, required: true
    parameter :neighborhood_id, type: :integer, required: true

    let(:user) { FactoryBot.create(:public_user) }
    let(:token) { user.token }
    let(:neighborhood) { FactoryBot.create(:neighborhood) }
    let(:neighborhood_id) { neighborhood.id }
    let!(:chat_message) { FactoryBot.create(:chat_message, messageable: neighborhood) }

    context '200' do
      let!(:join_request) { FactoryBot.create(:join_request, joinable: neighborhood, user: user, status: :accepted) }

      example_request 'Get chat_messages' do
        expect(response_status).to eq(200)
      end
    end

    context '401' do
      example_request 'Cannot see chat_messages if the user does not belong to the neighborhood' do
        expect(response_status).to eq(401)
      end
    end
  end

  post '/api/v1/neighborhoods/:neighborhood_id/chat_messages' do
    route_summary "Create chat_messages"
    # route_description "no description"

    parameter :token, type: :string, required: true
    parameter :neighborhood_id, type: :integer, required: true

    with_options :scope => :chat_message, :required => true do
      parameter :content, type: :string
      parameter :message_type, "text, status_update, share", type: :string
    end

    let(:user) { FactoryBot.create(:pro_user) }
    let(:neighborhood) { FactoryBot.create(:neighborhood) }
    let(:neighborhood_id) { neighborhood.id }
    let(:chat_message) { FactoryBot.create(:chat_message, messageable: neighborhood) }

    let(:parent_id) { nil }

    let(:raw_post) { {
      token: user.token,
      chat_message: {
        content: "foo",
        parent_id: parent_id
      }
    }.to_json }

    context '201' do
      let!(:join_request) { FactoryBot.create(:join_request, joinable: neighborhood, user: user, status: :accepted) }

      context 'Simple chat_message' do
        example_request 'Create chat_message' do
          expect(response_status).to eq(201)
          expect(JSON.parse(response_body)).to have_key('chat_message')
        end
      end

      context 'chat_message as a comment of another chat_message' do
        let!(:parent_id) { chat_message.id }

        example_request 'Create chat_message as a comment of another chat_message' do
          expect(response_status).to eq(201)
          expect(JSON.parse(response_body)).to have_key('chat_message')
          # expect(JSON.parse(response_body)['chat_message']).to have_key('parent_id')
        end
      end
    end

    context '401' do
      example_request 'Cannot create chat_messages if the user does not belong to the neighborhood' do
        expect(response_status).to eq(401)
      end
    end
  end
end
