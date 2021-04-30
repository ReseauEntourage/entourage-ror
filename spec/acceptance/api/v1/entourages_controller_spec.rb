require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::EntouragesController do
  explanation "Entourages"
  header "Content-Type", "application/json"

  get '/api/v1/entourages' do
    route_summary "Allows users to find entourages for a given location."
    # route_description "no description"

    parameter :token, "User token", type: :string, required: true
    parameter :types, "Comma separated type codes", type: :string
    parameter :latitude, "User latitude", type: :number
    parameter :longitude, "User longitude", type: :number
    parameter :distance, "Distance from GPS coordinates from which Entourage should be found", type: :number
    parameter :page, type: :integer
    parameter :show_past_events, type: :boolean
    parameter :time_range, "Find entourages created in the last hours (default 24)", type: :integer
    parameter :before, type: :datetime
    parameter :partners_only, type: :boolean

    let(:user) { FactoryGirl.create(:public_user) }
    let!(:entourage) { FactoryGirl.create(:entourage, :joined, user: user, status: "open") }
    let(:token) { user.token }

    context '200' do
      example_request 'Get entourages' do
        expect(status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('entourages')
      end
    end
  end

  get 'api/v1/entourages/:id' do
    route_summary "Get an entourage"

    parameter :id, "Entourage id", required: true
    parameter :token, type: :string, required: true

    let(:entourage) { create :entourage }
    let(:id) { entourage.id }
    let(:user) { FactoryGirl.create(:public_user) }
    let(:token) { user.token }

    context '200' do
      example_request 'Get entourage' do
        expect(status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('entourage')
      end
    end
  end

  get 'api/v1/entourages/mine' do
    route_summary "Get the entourages the current user joined"

    parameter :token, type: :string, required: true

    let(:entourage) { create :entourage }
    let(:id) { entourage.id }
    let(:user) { FactoryGirl.create(:public_user) }
    let(:token) { user.token }

    context '200' do
      example_request 'Get joined entourages' do
        expect(status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('entourages')
      end
    end
  end

  get 'api/v1/entourages/owns' do
    route_summary "Get the entourages the current user created"

    parameter :token, type: :string, required: true

    let(:entourage) { create :entourage }
    let(:id) { entourage.id }
    let(:user) { FactoryGirl.create(:public_user) }
    let(:token) { user.token }

    context '200' do
      example_request 'Get owned entourages' do
        expect(status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('entourages')
      end
    end
  end

  get 'api/v1/entourages/invitees' do
    route_summary "Get the entourages the current user has been invited in"

    parameter :token, type: :string, required: true

    let(:user) { FactoryGirl.create(:public_user) }
    let(:entourage) { FactoryGirl.create(:entourage, status: :open) }
    let!(:entourage_invitations) { FactoryGirl.create(:entourage_invitation, invitable: entourage, invitee: user, status: "accepted") }
    let(:id) { entourage.id }
    let(:token) { user.token }

    context '200' do
      example_request 'Get invited entourages' do
        expect(status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('entourages')
      end
    end
  end
end
