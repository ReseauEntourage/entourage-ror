require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::Tours::ChatMessagesController do
  explanation "Chat messages"
  header "Content-Type", "application/json"

  get '/api/v1/tours/:tour_id/chat_messages' do
    route_summary "Find chat_messages a user has joined"
    # route_description "no description"

    parameter :token, type: :string, required: true
    parameter :tour_id, type: :integer, required: true

    let(:user) { FactoryBot.create(:public_user) }
    let(:token) { user.token }
    let(:tour) { FactoryBot.create(:tour) }
    let(:tour_id) { tour.id }
    let!(:chat_message) { FactoryBot.create(:chat_message, messageable: tour) }

    context '401' do
      example_request 'Cannot see chat_messages if the user does not belong to the tour' do
        expect(response_status).to eq(401)
      end
    end

    context '200' do
      let!(:join_request) { FactoryBot.create(:join_request, joinable: tour, user: user, status: :accepted) }

      example_request 'Get chat_messages' do
        expect(response_status).to eq(200)
      end
    end
  end

  post '/api/v1/tours/:tour_id/chat_messages' do
    route_summary "Create chat_messages"
    # route_description "no description"

    parameter :token, type: :string, required: true
    parameter :tour_id, type: :integer, required: true

    with_options :scope => :chat_message, :required => true do
      parameter :content, type: :string
      parameter :message_type, "text, status_update, share", type: :string
      with_options :scope => "chat_message[metadata]", :required => true do
        parameter :status, "(status_update)", type: :string
        parameter :outcome_success, "(status_update)", type: :boolean
        parameter :type, "entourage, poi (share)", type: :string
        parameter :uuid, "(share)", type: :string
      end
    end

    let(:user) { FactoryBot.create(:pro_user) }
    let(:tour) { FactoryBot.create(:tour) }
    let(:tour_id) { tour.id }

    let(:raw_post) { {
      token: user.token,
      chat_message: {
        content: "foo"
      }
    }.to_json }

    context '201' do
      let!(:join_request) { FactoryBot.create(:join_request, joinable: tour, user: user, status: :accepted) }

      example_request 'Create chat_message' do
        expect(response_status).to eq(201)
        expect(JSON.parse(response_body)).to have_key('chat_message')
      end
    end

    context '401' do
      example_request 'Cannot create chat_messages if the user does not belong to the tour' do
        expect(response_status).to eq(401)
      end
    end
  end
end
