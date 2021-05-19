require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::FeedsController do
  explanation "Feeds"
  header "Content-Type", "application/json"

  get 'api/v1/feeds' do
    route_summary "Get the feed"
    route_description "Gets the list of actions and outings"

    parameter :token, type: :string, required: true
    parameter :latitude, type: :number
    parameter :longitude, type: :number
    parameter :show_past_events, type: :boolean
    parameter :partners_only, type: :boolean
    parameter :distance, type: :number
    parameter :announcements, "Insert announcements when equals to v1", type: :string
    parameter :page_token
    parameter :before, type: :boolean
    parameter :time_range, type: :integer

    let(:user) { FactoryGirl.create(:pro_user) }
    let(:entourage) { FactoryGirl.create(:entourage, updated_at: 4.hours.ago, created_at: 4.hours.ago, entourage_type: "ask_for_help") }

    let(:token) { user.token }
    let(:announcements) { 'v1' }
    let(:latitude) { entourage.latitude }
    let(:longitude) { entourage.longitude }

    context '200' do
      example_request 'Get feed' do
        expect(status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('feeds')
      end
    end
  end

  get 'api/v1/feeds/outings' do
    route_summary "Get outings"

    parameter :token, type: :string, required: true
    parameter :latitude, type: :number, required: true
    parameter :longitude, type: :number, required: true
    parameter :starting_after, type: :datetime

    let(:user) { FactoryGirl.create(:pro_user) }
    let(:token) { user.token }
    let!(:outing) { FactoryGirl.create(:outing, {metadata: {starts_at: 2.hours.ago}, latitude: 1, longitude: 1}) }
    let(:latitude) { 1 }
    let(:longitude) { 1 }

    context '200' do
      example_request 'Get outings' do
        expect(status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('feeds')
      end
    end
  end
end
