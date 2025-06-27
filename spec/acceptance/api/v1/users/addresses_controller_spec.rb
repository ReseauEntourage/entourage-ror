require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::Users::AddressesController do
  explanation "Addresses"
  header "Content-Type", "application/json"

  post '/api/v1/users/:user_id/addresses/:position' do
    route_summary "Create or update address"

    parameter :token, type: :string, required: true
    parameter :user_id, "me", type: :string, required: true
    parameter :position, type: :number, required: true
    with_options :scope => :address, :required => true do
      parameter :place_name, type: :string
      parameter :latitude, type: :number
      parameter :longitude, type: :number
    end

    let(:user) { FactoryBot.create(:pro_user) }
    let(:position) { 1 }

    let(:raw_post) { {
      token: user.token,
      address: {
        place_name: 'Work',
        latitude: 48.3,
        longitude: 2.7,
      }
    }.to_json }

    before { EntourageServices::GeocodingService.stub(:search_postal_code) {
      ['FR', '75011', 'Paris']
    } }

    context '200' do
      let(:user_id) { "me" }

      example_request 'Create address at position for me' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('user')
      end
    end

    context '403' do
      let(:user_id) { user.id }

      example_request 'Create address at position for id is forbidden' do
        expect(response_status).to eq(403)
      end
    end
  end

  delete '/api/v1/users/:user_id/addresses/:position' do
    route_summary "Delete user address"

    parameter :token, type: :string, required: true
    parameter :user_id, "me", type: :string, required: true
    parameter :position, type: :number, required: true

    let(:user) { FactoryBot.create(:pro_user) }
    let(:user_id) { "me" }

    let!(:address_1) { create(:address, :blank, position: 1, place_name: 'home', latitude: 48.3, longitude: 2.7, user_id: user.id) }
    let!(:address_2) { create(:address, :blank, position: 2, place_name: 'work', latitude: 48.3, longitude: 2.7, user_id: user.id) }

    let(:raw_post) { {
      token: user.token,
    }.to_json }

    before { EntourageServices::GeocodingService.stub(:search_postal_code) {
      ['FR', '75011', 'Paris']
    } }

    context '200' do
      let(:position) { 2 }

      example_request 'Delete address' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('user')
      end
    end

    context '400' do
      let(:position) { 1 }

      example_request 'Can not delete first address' do
        expect(response_status).to eq(400)
      end
    end
  end
end
