require 'rails_helper'
include AuthHelper

RSpec.describe Api::V0::RegistrationRequestsController, type: :controller do
  render_views

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
