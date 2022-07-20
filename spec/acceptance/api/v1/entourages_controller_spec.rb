require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::EntouragesController do
  explanation "Entourages"
  header "Content-Type", "application/json"

  get '/api/v1/entourages' do
    route_summary "Find entourages for a given location."
    # route_description "no description"

    parameter :token, "User token", type: :string, required: true
    parameter :types, "Comma separated; see: app/services/feed_services/types.rb", type: :string
    parameter :latitude, "User latitude", type: :number, required: true
    parameter :longitude, "User longitude", type: :number, required: true
    parameter :distance, "Distance from GPS coordinates from which Entourage should be found (km)", type: :number, default: 10
    parameter :page, type: :integer, default: 1
    parameter :per, type: :integer, default: 25
    parameter :show_past_events, "True to include past events in the results", type: :boolean, default: false
    parameter :time_range, "Find entourages created in the last hours", type: :integer, default: 24
    parameter :before, "Find entourages created before a date, when no pagination is given", type: :datetime, default: nil
    parameter :partners_only, "Boolean to get only partners", type: :boolean, default: false
    parameter :status, "open, closed, full, suspended, blacklisted", type: :string, default: :open

    let(:user) { FactoryBot.create(:public_user) }
    let!(:entourage) { FactoryBot.create(:entourage, :joined, user: user, status: "open") }
    let(:token) { user.token }

    context '200' do
      example_request 'Get entourages' do
        expect(response_status).to eq(200)
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
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('entourage')
      end
    end
  end

  get 'api/v1/entourages/search' do
    route_summary "Get the entourages corresponding to a search in the past month"

    parameter :token, type: :string, required: true
    parameter :q, "A search string", type: :string, required: true
    parameter :types, "Comma separated; see: app/services/feed_services/types.rb", type: :string
    parameter :latitude, "User latitude", type: :number, required: true
    parameter :longitude, "User longitude", type: :number, required: true
    parameter :page, type: :integer, default: 1
    parameter :per, type: :integer, default: 25

    let(:user) { FactoryBot.create(:public_user) }
    let!(:entourage) { FactoryBot.create(:entourage, :joined, user: user, status: "open", title: "solidarity coffee") }
    let(:token) { user.token }
    let(:q) { "coffee" }

    context '200' do
      example_request 'Get entourages from search' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('entourages')
      end
    end
  end

  get 'api/v1/entourages/joined' do
    route_summary "Get the entourages the current user joined in the past year"

    parameter :token, type: :string, required: true
    parameter :page, type: :integer, default: 1
    parameter :per, type: :integer, default: 25

    let(:user) { FactoryBot.create(:public_user) }
    let(:entourage) { create :entourage, status: :open }
    let!(:join_request) { FactoryBot.create(:join_request, joinable: entourage, user: user, status: "accepted") }
    let(:token) { user.token }

    context '200' do
      example_request 'Get joined entourages' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('entourages')
      end
    end
  end

  get 'api/v1/entourages/owned' do
    route_summary "Get the actions the current user created in the past year"

    parameter :token, type: :string, required: true
    parameter :page, type: :integer, default: 1
    parameter :per, type: :integer, default: 25

    let(:user) { FactoryBot.create(:public_user) }
    let!(:entourage) { create :entourage, status: :open, user: user }
    let(:token) { user.token }

    context '200' do
      example_request 'Get owned entourages' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('entourages')
      end
    end
  end

  get 'api/v1/entourages/invited' do
    route_summary "Get the entourages the current user has been invited in, in the past year"

    parameter :token, type: :string, required: true
    parameter :page, type: :integer, default: 1
    parameter :per, type: :integer, default: 25

    let(:user) { FactoryBot.create(:public_user) }
    let(:entourage) { FactoryBot.create(:entourage, status: :open) }
    let!(:entourage_invitations) { FactoryBot.create(:entourage_invitation, invitable: entourage, invitee: user, status: "accepted") }
    let(:token) { user.token }

    context '200' do
      example_request 'Get invited entourages' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('entourages')
      end
    end
  end

  post 'api/v1/entourages' do
    route_summary "Creates an action"

    parameter :token, type: :string, required: true

    with_options :scope => :entourage, :required => true do
      parameter :group_type, "action", required: true
      parameter :title, "Title"
      with_options :scope => "entourage[location]", :required => true do
        parameter :latitude, "Latitude", type: :number
        parameter :longitude, "Longitude", type: :number
      end
      parameter :entourage_type, "contribution or ask_for_help"
      parameter :display_category, "mat_help, social, resource, info, skill, event or other", required: false
      parameter :status, required: false
      parameter :description, required: false
      parameter :category, "mat_help, non_mat_help or social", required: false
      parameter :public, "deprecated", required: false
      with_options :scope => "entourage[outcome]", :required => false do
        parameter :success, "whether the action was successful or not"
      end
      parameter :recipient_consent_obtained, "Consent is required when creating an action for someone else", required: false
      with_options :scope => "entourage[metadata]" do
        parameter :display_address, "Address", type: :string
        parameter :city, "City", type: :string
        parameter :close_message, "A message to post when closing an action", type: :string, :required => false
      end
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
        expect(response_status).to eq(201)
        expect(JSON.parse(response_body)).to have_key('entourage')
      end
    end
  end

  post 'api/v1/entourages' do
    route_summary "Creates an outing"

    parameter :token, type: :string, required: true

    with_options :scope => :entourage, :required => true do
      parameter :group_type, "outing", required: true
      parameter :title, "Title"
      with_options :scope => "entourage[location]", :required => true do
        parameter :latitude, "Latitude", type: :number
        parameter :longitude, "Longitude", type: :number
      end
      parameter :entourage_type, "contribution or ask_for_help"
      parameter :display_category, "mat_help, social, resource, info, skill, event or other", required: false
      parameter :status, required: false
      parameter :description, required: false
      parameter :category, "mat_help, non_mat_help or social", required: false
      parameter :public, "deprecated", required: false
      with_options :scope => "entourage[metadata]", :required => true do
        parameter :starts_at, "Start date"
        parameter :place_name, "Place name", required: false
        parameter :street_address, "Street address", required: false
        parameter :google_place_id, "Google place ID", required: false
        parameter :landscape_url, "Path to a 1125 x 375px image url", required: false
        parameter :landscape_thumbnail_url, "Path to a thumbnail of 1125 x 375px image url", required: false
        parameter :portrait_url, "Path to a 300 x 492px image url", required: false
        parameter :portrait_thumbnail_url, "Path to a thumbnail of 300 x 492px image url", required: false
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
          landscape_thumbnail_url: outing.metadata[:landscape_thumbnail_url],
          portrait_url: outing.metadata[:portrait_url],
          portrait_thumbnail_url: outing.metadata[:portrait_thumbnail_url],
        }
      }
    }.to_json }

    context '201' do
      example_request 'Create outing' do
        expect(response_status).to eq(201)
        expect(JSON.parse(response_body)).to have_key('entourage')
      end
    end
  end

  patch 'api/v1/entourages/:id' do
    route_summary "Updates an entourage"

    parameter :id, required: true
    parameter :token, type: :string, required: true

    with_options :scope => :entourage, :required => true do
      parameter :title, "Title"
      with_options :scope => "entourage[location]", :required => true do
        parameter :latitude, "Latitude", type: :number
        parameter :longitude, "Longitude", type: :number
      end
      parameter :entourage_type, "contribution or ask_for_help"
      parameter :display_category, "mat_help, social, resource, info, skill, event or other", required: false
      parameter :status, required: false
      parameter :description, required: false
      parameter :category, "mat_help, non_mat_help or social", required: false
      parameter :public, "deprecated", required: false
      with_options :scope => "entourage[outcome]", :required => false do
        parameter :success, "whether the action was successful or not"
      end
      parameter :recipient_consent_obtained, "Consent is required when creating an action for someone else", required: false
      with_options :scope => "entourage[metadata]" do
        parameter :display_address, "Address", type: :string
        parameter :city, "City", type: :string
        parameter :close_message, "A message to post when closing an action", type: :string, :required => false
      end
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
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('entourage')
      end
    end
  end

  patch 'api/v1/entourages/:id' do
    route_summary "Updates an outing"

    parameter :id, required: true
    parameter :token, type: :string, required: true

    with_options :scope => :entourage, :required => true do
      parameter :title, "Title"
      with_options :scope => "entourage[location]", :required => true do
        parameter :latitude, "Latitude", type: :number
        parameter :longitude, "Longitude", type: :number
      end
      parameter :entourage_type, "contribution or ask_for_help"
      parameter :display_category, "mat_help, social, resource, info, skill, event or other", required: false
      parameter :status, required: false
      parameter :description, required: false
      parameter :category, "mat_help, non_mat_help or social", required: false
      parameter :public, "deprecated", required: false
      with_options :scope => "entourage[metadata]", required: true do
        parameter :starts_at, "Start date"
        parameter :place_name, "Place name", required: false
        parameter :street_address, "Street address", required: false
        parameter :google_place_id, "Google place ID", required: false
        parameter :landscape_url, "Path to a 1125 x 375px image url", required: false
        parameter :landscape_thumbnail_url, "Path to a thumbnail of 1125 x 375px image url", required: false
        parameter :portrait_url, "Path to a 300 x 492px image url", required: false
        parameter :portrait_thumbnail_url, "Path to a thumbnail of 300 x 492px image url", required: false
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
          landscape_thumbnail_url: "path/to/landscape_thumbnail_url",
          portrait_url: "path/to/portrait_url",
          portrait_thumbnail_url: "path/to/portrait_thumbnail_url",
        }
      }
    }.to_json }

    context '200' do
      example_request 'Update outing' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('entourage')
      end
    end
  end

  put 'api/v1/entourages/:id/read' do
    route_summary "Mark entourage as read"

    parameter :id, required: true
    parameter :token, type: :string, required: true

    let(:entourage) { create :entourage }
    let(:user) { FactoryBot.create(:public_user) }
    let!(:join_request) { FactoryBot.create(:join_request, joinable: entourage, user: user, status: JoinRequest::ACCEPTED_STATUS, last_message_read: DateTime.parse("15/10/2010")) }

    let(:id) { entourage.id }
    let(:raw_post) { {
      token: user.token
    }.to_json }

    context '204' do
      example_request 'Read entourage' do
        expect(response_status).to eq(204)
      end
    end
  end

  post 'api/v1/entourages/:id/report' do
    route_summary "Sends an alert about an entourage"

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


    ENV['ADMIN_HOST'] = 'https://this.is.local'
    ENV['SLACK_SIGNAL'] = '{"url":"https://url.to.slack.com","channel":"channel"}'

    before { stub_request(:post, "https://url.to.slack.com").to_return(status: 200) }

    context '201' do
      example_request 'Report entourage' do
        expect(response_status).to eq(201)
      end
    end
  end

  delete 'api/v1/entourages/:id/report_prompt' do
    route_summary "Deletes a prompt message, displayed at first direct message from a user in an action or outing"

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
        expect(response_status).to eq(204)
      end
    end
  end
end
