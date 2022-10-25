require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::PoisController do
  explanation "Pois"
  header "Content-Type", "application/json"

  get '/api/v1/pois' do
    route_summary "Find POI for a given location."
    route_description "To find Pois from Soliguide, values (v=2, no_redirect!='true') are expected. Soliguide is currently provided only for Paris."

    parameter :v, "Version to be used, 1 or 2 (default 1)", type: :integer
    parameter :latitude, "User latitude", type: :number, required: true
    parameter :longitude, "User longitude", type: :number, required: true
    parameter :distance, "Distance from GPS coordinates from which POI should be found", type: :number
    parameter :category_ids, "Comma separated category_ids", type: :string
    parameter :partners_filters, "Comma separated partners (either donations or volunteers)", type: :string
    parameter :query, "Filter POI by name", type: :string
    parameter :no_redirect, type: :boolean

    let!(:category) { create :category }
    let!(:poi) { create :poi, category: category, validated: true }

    let(:v) { 1 }
    let(:latitude) { poi.latitude }
    let(:longitude) { poi.longitude }
    let(:category_ids) { category.id }

    context '200' do
      example_request 'Get pois' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('pois')
      end
    end
  end

  get 'api/v1/pois/:id' do
    route_summary "Get a POI"

    parameter :id, required: true

    let(:poi) { create :poi }
    let(:id) { poi.id }

    context '200' do
      example_request 'Get poi' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('poi')
      end
    end
  end

  # @nodoc for post 'api/v1/pois'
  # it is available only using typeform

  post 'api/v1/pois/:id/report' do
    route_summary "Report a POI to Entourage team"

    parameter :token, type: :string, required: true
    parameter :id, type: :integer, required: true
    parameter :message, type: :string, required: true

    let!(:mail) { spy('mail') }
    let!(:member_mailer) { spy('member_mailer', poi_report: mail) }

    let!(:poi) { create :poi }
    let(:user) { FactoryBot.create(:pro_user) }

    let(:id) { poi.id }
    let(:raw_post) { {
      token: user.token,
      message: "message"
    }.to_json }

    context '201' do
      example_request 'Report a POI to Entourage team' do
        expect(response_status).to eq(201)
        expect(JSON.parse(response_body)).to have_key('message')
      end
    end
  end
end
