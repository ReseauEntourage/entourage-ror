require 'rails_helper'

RSpec.describe Api::V1::Users::AddressesController, type: :controller do

  let(:user) { create :public_user }
  let(:result) { JSON.parse(response.body) }
  let(:home) { {place_name: 'Maison',  latitude: 45.2, longitude: 3.7} }
  let(:work) { {place_name: 'Travail', latitude: 44.7, longitude: 3.1} }

  describe 'POST :position' do
    describe "create first address" do
      before { post :create_or_update, position: 1, address: home, user_id: 'me', token: user.token }

      it { expect(response.status).to eq(200) }
      it { expect(result).to eq(
        "address"=>{
          "display_address"=>"Maison",
          "latitude"=>45.2,
          "longitude"=>3.7,
          "position"=>1
        }
      )}
      it { expect(user.reload.address_id).to eq(user.addresses.first.id) }
    end

    describe "create second address" do
      before { post :create_or_update, position: 2, address: work, user_id: 'me', token: user.token }

      it { expect(response.status).to eq(200) }
      it { expect(result).to eq(
        "address"=>{
          "display_address"=>"Travail",
          "latitude"=>44.7,
          "longitude"=>3.1,
          "position"=>2,
        }
      )}
      it { expect(user.reload.address_id).to be_nil }
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
      it { expect(result).to eq(
        "address"=>{
          "display_address"=>"Travail",
          "latitude"=>44.7,
          "longitude"=>3.1,
          "position"=>1
        }
      )}
      it { expect(user.reload.address_id).to eq first_address.id }
    end

    describe "update second address" do
      let!(:second_address) { create(:address, :blank, work.merge(position: 2, user_id: user.id)).reload }
      before { post :create_or_update, position: 2, address: home, user_id: 'me', token: user.token }

      it { expect(response.status).to eq(200) }
      it { expect(result).to eq(
        "address"=>{
          "display_address"=>"Maison",
          "latitude"=>45.2,
          "longitude"=>3.7,
          "position"=>2,
        }
      )}
      it { expect(user.reload.address_id).to be_nil }
    end
  end

  describe 'DELETE :position' do
    describe "delete first address" do
      let!(:first_address) { create(:address, :blank, home.merge(position: 1, user_id: user.id)).reload }

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
      let!(:second_address) { create(:address, :blank, work.merge(position: 2, user_id: user.id)).reload }

      before { delete :destroy, position: 2, user_id: 'me', token: user.token }

      it { expect(response.status).to eq(204) }
      it { expect(response.body).to eq '' }
      it { expect(user.reload.address_2).to be_nil }
    end


    describe "delete second address when it doesn't exist" do
      before { delete :destroy, position: 2, user_id: 'me', token: user.token }

      it { expect(response.status).to eq(204) }
      it { expect(response.body).to eq '' }
      it { expect(user.reload.address_2).to be_nil }
    end
  end
end
