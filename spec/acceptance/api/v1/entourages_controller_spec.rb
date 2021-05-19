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

    let(:user) { FactoryBot.create(:public_user) }
    let!(:entourage) { FactoryBot.create(:entourage, :joined, user: user, status: "open") }
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

    parameter :id, required: true
    parameter :token, type: :string, required: true

    let(:entourage) { create :entourage }
    let(:id) { entourage.id }
    let(:user) { FactoryBot.create(:public_user) }
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
    let(:user) { FactoryBot.create(:public_user) }
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
    let(:user) { FactoryBot.create(:public_user) }
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

    let(:user) { FactoryBot.create(:public_user) }
    let(:entourage) { FactoryBot.create(:entourage, status: :open) }
    let!(:entourage_invitations) { FactoryBot.create(:entourage_invitation, invitable: entourage, invitee: user, status: "accepted") }
    let(:id) { entourage.id }
    let(:token) { user.token }

    context '200' do
      example_request 'Get invited entourages' do
        expect(status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('entourages')
      end
    end
  end

  post 'api/v1/entourages' do
    route_summary "Creates an entourage"

    parameter :token, type: :string, required: true

    with_options :scope => :entourage, :required => true do
      parameter :title
      with_options :scope => "entourage[location]", :required => true do
        parameter :latitude
        parameter :longitude
      end
      parameter :entourage_type
      parameter :display_category, required: false
      parameter :description, required: false
      parameter :category, required: false
      parameter :recipient_consent_obtained, required: false
    end

    let(:entourage) { build :entourage }
    let(:user) { FactoryBot.create(:pro_user) }

    let(:raw_post) { {
      token: user.token,
      entourage: {
        title: entourage.title,
        location: {
          latitude: entourage.latitude,
          longitude: entourage.longitude,
        },
        entourage_type: entourage.entourage_type,
        display_category: entourage.display_category,
        description: entourage.description,
        category: entourage.category,
        recipient_consent_obtained: true
      }
    }.to_json }

    context '201' do
      example_request 'Create entourage' do
        expect(status).to eq(201)
        expect(JSON.parse(response_body)).to have_key('entourage')
      end
    end
  end

  post 'api/v1/entourages' do
    route_summary "Creates an outing"

    parameter :token, type: :string, required: true

    with_options :scope => :entourage, :required => true do
      parameter :title
      with_options :scope => "entourage[location]", :required => true do
        parameter :latitude
        parameter :longitude
      end
      with_options :scope => "entourage[metadata]", :required => true do
        parameter :starts_at
        parameter :place_name
        parameter :street_address
        parameter :google_place_id
        parameter :landscape_url, required: false
        parameter :portrait_url, required: false
      end
    end

    let(:outing) { build :outing }
    let(:user) { FactoryBot.create(:pro_user) }

    let(:raw_post) { {
      token: user.token,
      entourage: {
        group_type: :outing,
        title: outing.title,
        location: {
          latitude: outing.latitude,
          longitude: outing.longitude,
        },
        metadata: {
          starts_at: outing.metadata[:starts_at],
          place_name: outing.metadata[:place_name],
          street_address: outing.metadata[:street_address],
          google_place_id: outing.metadata[:google_place_id],
          landscape_url: outing.metadata[:landscape_url],
          portrait_url: outing.metadata[:portrait_url],
        }
      }
    }.to_json }

    context '201' do
      example_request 'Create outing' do
        expect(status).to eq(201)
        expect(JSON.parse(response_body)).to have_key('entourage')
      end
    end
  end

  patch 'api/v1/entourages/:id' do
    route_summary "Updates an entourage"

    parameter :id, required: true
    parameter :token, type: :string, required: true

    with_options :scope => :entourage, :required => true do
      parameter :title, required: false
      with_options :scope => "entourage[location]" do
        parameter :latitude, required: false
        parameter :longitude, required: false
      end
      parameter :entourage_type, required: false
      parameter :display_category, required: false
      parameter :description, required: false
      parameter :category, required: false
      parameter :recipient_consent_obtained, required: false
    end

    let(:user) { FactoryBot.create(:pro_user) }
    let(:entourage) { FactoryBot.create(:entourage, :joined, user: user) }

    let(:id) { entourage.id }
    let(:raw_post) { {
      token: user.token,
      entourage: {
        title: entourage.title
      }
    }.to_json }

    context '200' do
      example_request 'Update entourage' do
        expect(status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('entourage')
      end
    end
  end

  patch 'api/v1/entourages/:id' do
    route_summary "Updates an outing"

    parameter :id, required: true
    parameter :token, type: :string, required: true

    with_options :scope => :entourage, :required => true do
      parameter :title, required: false
      with_options :scope => "entourage[location]" do
        parameter :latitude, required: false
        parameter :longitude, required: false
      end
      with_options :scope => "entourage[metadata]", :required => true do
        parameter :starts_at, required: false
        parameter :place_name, required: false
        parameter :street_address, required: false
        parameter :google_place_id, required: false
        parameter :landscape_url, required: false
        parameter :portrait_url, required: false
      end
    end

    let(:user) { FactoryBot.create(:pro_user) }
    let(:outing) { FactoryBot.create(:outing, user: user) }

    let(:id) { outing.id }
    let(:raw_post) { {
      token: user.token,
      entourage: {
        metadata: {
          landscape_url: "path/to/landscape_url",
          portrait_url: "path/to/portrait_url",
        }
      }
    }.to_json }

    context '200' do
      example_request 'Update outing' do
        expect(status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('entourage')
      end
    end
  end

  put 'api/v1/entourages/:id/read' do
    route_summary "Reads an entourage"

    parameter :id, required: true
    parameter :token, type: :string, required: true

    let(:entourage) { create :entourage }
    let(:user) { FactoryBot.create(:public_user) }
    let(:old_date) { DateTime.parse("15/10/2010") }
    let!(:join_request) { FactoryBot.create(:join_request, joinable: entourage, user: user, status: JoinRequest::ACCEPTED_STATUS, last_message_read: old_date) }

    let(:id) { entourage.id }
    let(:raw_post) { {
      token: user.token
    }.to_json }

    context '204' do
      example_request 'Read entourage' do
        expect(status).to eq(204)
      end
    end
  end

  post 'api/v1/entourages/:id/report' do
    route_summary "Reports an entourage"

    parameter :id, required: true
    parameter :token, type: :string, required: true
    with_options :scope => :entourage_report, :required => true do
      parameter :message, type: :string
    end

    let(:entourage) { create :entourage }
    let(:user) { FactoryBot.create(:public_user) }

    let(:id) { entourage.id }
    let(:raw_post) { {
      token: user.token,
      entourage_report: {
        message: 'message'
      }
    }.to_json }

    context '201' do
      example_request 'Report entourage' do
        expect(status).to eq(201)
      end
    end
  end

  delete 'api/v1/entourages/:id/report_prompt' do
    route_summary "Deletes a report prompt"

    parameter :id, required: true
    parameter :token, type: :string, required: true

    let(:entourage) { create :entourage }
    let(:user) { FactoryBot.create(:public_user) }

    let(:id) { entourage.id }
    let(:raw_post) { {
      token: user.token,
    }.to_json }

    context '204' do
      example_request 'Delete entourage report_prompt' do
        expect(status).to eq(204)
      end
    end
  end
end
