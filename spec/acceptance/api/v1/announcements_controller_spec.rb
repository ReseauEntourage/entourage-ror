require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::AnnouncementsController do
  explanation "Announcements"
  header "Content-Type", "application/json"

  get '/api/v1/announcements' do
    route_summary "Allows users to find announcements that fit her goal and area"
    # route_description "no description"

    parameter :token, "User token", type: :string, required: true

    let(:address) { FactoryBot.create(:address) }
    let(:user) { FactoryBot.create(:public_user, goal: :offer_help, addresses: [address]) }
    let!(:announcement) { FactoryBot.create(:announcement, user_goals: [:offer_help], areas: [:dep_75]) }
    let(:token) { user.token }

    context '200' do
      example_request 'Get announcements' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('announcements')
      end
    end
  end

  get '/api/v1/announcements/:id/icon' do
    route_summary "Announcement icon"

    parameter :id, required: true
    parameter :token, "User token", type: :string, required: true

    let(:user) { FactoryBot.create(:public_user) }
    let(:announcement) { FactoryBot.create(:announcement, icon: 'icon.png', user_goals: [:offer_help], areas: [:dep_75]) }

    let(:id) { announcement.id }
    let(:token) { user.token }

    context '200' do
      example_request 'Get announcement icon' do
        expect(response_status).to eq(302)
      end
    end
  end

  get '/api/v1/announcements/:id/redirect/:token' do
    route_summary "Announcement redirection whenever a given announcement has defined an URL"

    parameter :id, required: true
    parameter :token, "User token", type: :string, required: true

    let(:user) { FactoryBot.create(:public_user) }
    let(:announcement) { FactoryBot.create(:announcement, url: 'https://www.google.fr/', user_goals: [:offer_help], areas: [:dep_75]) }

    let(:id) { announcement.id }
    let(:token) { user.token }

    context '200' do
      example_request 'Get announcement redirection' do
        expect(response_status).to eq(302)
      end
    end
  end
end
