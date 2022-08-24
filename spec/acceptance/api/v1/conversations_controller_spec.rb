require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::ConversationsController do
  explanation "Conversations"
  header "Content-Type", "application/json"

  get '/api/v1/conversations' do
    route_summary "Find conversations"

    parameter :token, type: :string, required: true

    # users
    let(:user) { FactoryBot.create(:pro_user) }
    let(:other_user) { FactoryBot.create(:public_user, first_name: 'Michel', last_name: 'Ange') }

    # conversations
    let!(:entourage) { FactoryBot.create(:entourage, status: :open) }
    let!(:conversation) { FactoryBot.create(:conversation, user: user, participants: [other_user]) }

    # memberships
    let!(:join_request_1) { FactoryBot.create(:join_request, joinable: entourage, user: user, status: :accepted, last_message_read: Time.now) }
    let!(:join_request_2) { FactoryBot.create(:join_request, joinable: conversation, user: user, status: :accepted, last_message_read: Time.now) }

    let(:token) { user.token }

    subject { JSON.parse(response_body) }

    context '200' do
      example_request 'Get conversations' do
        expect(response_status).to eq(200)
        expect(subject).to have_key('conversations')
        expect(subject["conversations"].count).to eq(2)
        expect(subject["conversations"][0]["name"]).to eq("Michel A.")
      end
    end
  end

  get 'api/v1/conversations/:id' do
    route_summary "Get a conversation"

    parameter :id, required: true
    parameter :token, type: :string, required: true

    let(:user) { FactoryBot.create(:pro_user) }
    let(:token) { user.token }
    let(:conversation) { create :conversation }
    let(:id) { conversation.id }
    let!(:join_request) { FactoryBot.create(:join_request, joinable: conversation, user: user, status: :accepted) }

    context '200' do
      example_request 'Get conversation' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('conversation')
      end
    end
  end

  post '/api/v1/conversations' do
    route_summary "Create private conversation"
    # route_description "no description"

    parameter :token, type: :string, required: true

    with_options :scope => :conversation, :required => true do
      parameter :user_id, type: :integer
    end

    let(:user) { FactoryBot.create(:pro_user) }
    let(:other_user) { FactoryBot.create(:pro_user) }

    let(:raw_post) { {
      token: user.token,
      conversation: {
        user_id: other_user.id
      }
    }.to_json }

    subject { JSON.parse(response_body) }

    context '201' do
      example_request 'Create conversation' do
        expect(response_status).to eq(201)
        expect(subject).to have_key('conversation')
        expect(subject['conversation']['members_count']).to eq(2)
      end
    end
  end
end
