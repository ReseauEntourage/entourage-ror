require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::MyfeedsController do
  explanation "MyFeeds"
  header "Content-Type", "application/json"

  get 'api/v1/myfeeds' do
    route_summary "Get the feed"
    route_description "Gets the list of actions and outings"

    parameter :token, type: :string, required: true
    parameter :page, "Page", type: :integer, default: 1
    parameter :per, "Page", type: :integer, default: 25
    parameter :unread_only, "Only unread entourages", type: :boolean, default: false

    let(:user) { FactoryBot.create(:pro_user) }
    let(:token) { user.token }

    context '200' do
      let(:other_user) { create :public_user }
      let!(:entourage) { FactoryBot.create(:entourage, :joined, join_request_user: user, user: other_user, created_at: 1.hour.ago) }

      example_request 'Get the feed' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('feeds')
      end
    end
  end
end
