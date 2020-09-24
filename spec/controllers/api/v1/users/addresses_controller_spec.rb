require 'rails_helper'

RSpec.describe Api::V1::Users::AddressesController, type: :controller do

  let(:user) { create :public_user }
  let(:result) { JSON.parse(response.body) }
  let(:home) { {place_name: 'Maison',  latitude: 45.2, longitude: 3.7} }
  let(:work) { {place_name: 'Travail', latitude: 44.7, longitude: 3.1} }

  let!(:stub_gmaps) do
    Geocoder.configure(api_key: 'something')

    stub_request(:get, /maps.googleapis.com/).
    to_return do |request|
      postal_code =
        case request.uri
        when /latlng=45.2,3.7/
          '75011'
        when /latlng=44.7,3.1/
          '92001'
        else
          '12345'
        end

      {status: 200, body: JSON.fast_generate(status: :OK, results: [{
        types: [:postal_code], address_components: [
          {long_name: postal_code, types: [:postal_code]},
          {short_name: 'FR', types: [:country]}
        ]
      }])}
    end
  end

  describe 'POST :position' do
    describe "create first address" do
      before { post :create_or_update, position: 1, address: home, user_id: 'me', token: user.token }

      it { expect(response.status).to eq(200) }
      it { expect(result).to match(
        "user" => hash_including(
          "address"=>{
            "display_address"=>"Maison, 75011",
            "latitude"=>45.2,
            "longitude"=>3.7,
            "position"=>1
          },
          "firebase_properties"=>hash_including(
            "ActionZoneCP"=>"75011",
            "ActionZoneDep"=>"75"
          )
        )
      )}
    end

    describe "create second address" do
      let!(:first_address) { create(:address, :blank, home.merge(position: 1, country: 'FR', postal_code: '75011', user_id: user.id)) }

      before { post :create_or_update, position: 2, address: work, user_id: 'me', token: user.token }

      it { expect(response.status).to eq(200) }
      it { expect(result).to match(
        "user" => hash_including(
          "address"=>hash_including("display_address"=>"Maison, 75011"),
          "address_2"=>{
            "display_address"=>"Travail, 92001",
            "latitude"=>44.7,
            "longitude"=>3.1,
            "position"=>2,
          },
          "firebase_properties"=>hash_including(
            "ActionZoneCP"=>"75011,92001",
            "ActionZoneDep"=>"75,92"
          )
        )
      )}
    end

    describe "create third address" do
      before { post :create_or_update, position: 3, address: work, user_id: 'me', token: user.token }

      it { expect(response.status).to eq(400) }
      it { expect(result).to eq(
        "error"=>{
          "code"=>"CANNOT_UPDATE_ADDRESS",
          "message"=>["Position doit être inférieur ou égal à 2"]
        }
      )}
    end

    describe "update first address" do
      let!(:first_address) { create(:address, :blank, home.merge(position: 1, user_id: user.id)).reload }
      before { post :create_or_update, position: 1, address: work, user_id: 'me', token: user.token }

      it { expect(response.status).to eq(200) }
      it { expect(result).to match(
        "user" => hash_including(
          "address"=>{
            "display_address"=>"Travail, 92001",
            "latitude"=>44.7,
            "longitude"=>3.1,
            "position"=>1
          },
          "firebase_properties"=>hash_including(
            "ActionZoneCP"=>"92001",
            "ActionZoneDep"=>"92"
          )
        )
      )}
    end

    describe "update second address" do
      let!(:second_address) { create(:address, :blank, work.merge(position: 2, user_id: user.id)).reload }
      before { post :create_or_update, position: 2, address: home, user_id: 'me', token: user.token }

      it { expect(response.status).to eq(200) }
      it { expect(result).to match(
        "user" => hash_including(
          "address_2"=>{
            "display_address"=>"Maison, 75011",
            "latitude"=>45.2,
            "longitude"=>3.7,
            "position"=>2,
          },
          "firebase_properties"=>hash_including(
            "ActionZoneCP"=>"75011",
            "ActionZoneDep"=>"75"
          )
        )
      )}
    end
  end

  describe 'DELETE :position' do
    let!(:first_address) { create(:address, :blank, home.merge(position: 1, country: 'FR', postal_code: '75011', user_id: user.id)).reload }
    let!(:second_address) { create(:address, :blank, work.merge(position: 2, country: 'FR', postal_code: '92001', user_id: user.id)).reload }

    describe "delete first address" do
      before { delete :destroy, position: 1, user_id: 'me', token: user.token }

      it { expect(response.status).to eq(400) }
      it { expect(result).to eq(
        "error" => {
          "code" => "CANNOT_DELETE_ADDRESS",
          "message" => "Invalid address id"
        }
      )}
      it { expect(user.reload.address_id).to eq first_address.id }
    end

    describe "delete second address when it exists" do
      before { delete :destroy, position: 2, user_id: 'me', token: user.token }

      it { expect(response.status).to eq(200) }
      it { expect(result).to match(
        "user" => hash_including(
          "address"=>hash_including("display_address"=>"Maison, 75011"),
          "address_2"=>nil,
          "firebase_properties"=>hash_including(
            "ActionZoneCP"=>"75011",
            "ActionZoneDep"=>"75"
          )
        )
      )}
    end


    describe "delete second address when it doesn't exist" do
      before { delete :destroy, position: 2, user_id: 'me', token: user.token }
      it { expect(response.status).to eq(200) }
    end
  end
end
