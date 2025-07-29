require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::Neighborhoods::ChatMessagesController do
  explanation 'Chat messages'
  header 'Content-Type', 'application/json'

  get '/api/v1/neighborhoods/:neighborhood_id/chat_messages' do
    route_summary 'Find user chat_messages in a neighborhood'
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

    context '200' do
      example_request 'Non members can see chat_messages' do
        expect(response_status).to eq(200)
      end
    end
  end

  post '/api/v1/neighborhoods/:neighborhood_id/chat_messages' do
    route_summary 'Create chat_messages'
    # route_description "no description"

    parameter :token, type: :string, required: true
    parameter :neighborhood_id, type: :integer, required: true

    with_options scope: :chat_message, required: true do
      parameter :content, 'content is optional whenever image_url is defined', type: :string, required: false
      parameter :image_url, type: :string, required: false
      parameter :parent_id, 'parent chat_message id', required: false
    end

    let(:user) { FactoryBot.create(:pro_user) }
    let(:neighborhood) { FactoryBot.create(:neighborhood) }
    let(:neighborhood_id) { neighborhood.id }
    let(:chat_message) { FactoryBot.create(:chat_message, messageable: neighborhood) }

    let(:parent_id) { nil }

    let(:raw_post) { {
      token: user.token,
      chat_message: {
        content: 'foo',
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
        end
      end
    end

    context '401' do
      example_request 'Cannot create chat_messages if the user does not belong to the neighborhood' do
        expect(response_status).to eq(401)
      end
    end
  end

  post '/api/v1/neighborhoods/:neighborhood_id/chat_messages/presigned_upload' do
    route_summary 'Presigned upload'

    parameter :neighborhood_id, type: :integer, required: true
    parameter :token, type: :string, required: true
    parameter :content_type, 'image/jpeg, image/png', type: :string, required: true

    let(:user) { FactoryBot.create(:pro_user) }
    let(:neighborhood) { FactoryBot.create(:neighborhood) }
    let(:neighborhood_id) { neighborhood.id }
    let!(:join_request) { FactoryBot.create(:join_request, joinable: neighborhood, user: user, status: :accepted) }

    let(:raw_post) { {
      token: user.token,
      content_type: 'image/jpeg',
    }.to_json }

    context '200' do
      example_request 'Presigned upload' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('upload_key')
        expect(JSON.parse(response_body)).to have_key('presigned_url')
      end
    end
  end

  post 'api/v1/neighborhoods/:neighborhood_id/chat_messages/:chat_message_id/report' do
    route_summary 'Sends an alert about a chat_message'

    parameter :id, required: true
    parameter :token, type: :string, required: true
    with_options scope: :report, required: true do
      parameter :signals, type: :array
      parameter :message, type: :string
    end

    let(:user) { FactoryBot.create(:public_user) }

    let(:neighborhood) { create :neighborhood }
    let(:chat_message) { create :chat_message, messageable: neighborhood }
    let!(:join_request) { FactoryBot.create(:join_request, joinable: neighborhood, user: user, status: 'accepted') }

    let(:neighborhood_id) { neighborhood.id }
    let(:chat_message_id) { chat_message.id }
    let(:raw_post) { {
      token: user.token,
      report: {
        signals: ['spam'],
        message: 'message'
      }
    }.to_json }

    context '201' do
      example_request 'Report neighborhood' do
        expect(response_status).to eq(201)
      end
    end
  end
end
