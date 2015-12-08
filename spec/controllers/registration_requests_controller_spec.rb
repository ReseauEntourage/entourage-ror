require 'rails_helper'
include AuthHelper

RSpec.describe RegistrationRequestsController, type: :controller do

  let(:valid_attributes) {
    {organization: {name: "foo",
                    local_entity: "bar",
                    address: "2 rue de l'église",
                    phone: "+33612345678",
                    email: "some@email.com",
                    website_url: "http://foobar.com",
                    description: "lorem ipsum",
                    logo_key: "some_key.jpg"},
      user: {first_name: "John",
          last_name: "Doe",
          phone: "+33612345678",
          email: "some@email.com"}
    }
  }

  let(:invalid_attributes) {
    {organization: {}, user: {}}
  }

  describe "GET #index" do
    before { get :index }

    context "has registration requests" do
      let!(:registration_requests) { FactoryGirl.create_list(:registration_request, 2) }
      it { expect(assigns(:registration_requests)).to eq(registration_requests) }
    end

    context "no registration requests" do
      it { expect(assigns(:registration_requests)).to eq([]) }
    end
  end

  describe "POST #create" do
    context "with valid params" do
      before { post :create, {registration_request: valid_attributes} }
      it { expect(RegistrationRequest.count).to eq(1) }
      it { expect(response.status).to eq(201) }
    end

    context "with invalid params" do
      before { post :create, {registration_request: invalid_attributes} }
      it { expect(RegistrationRequest.count).to eq(0) }
      it { expect(response.status).to eq(400) }
      it { expect(JSON.parse(response.body)).to eq({"errors"=>{"organization"=>["Name can't be blank", "Description can't be blank", "Phone can't be blank", "Address can't be blank"], "user"=>[]}}) }
    end
  end
end
