require 'rails_helper'
include AuthHelper

RSpec.describe Api::V1::RegistrationRequestsController, type: :controller do
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
    {organization: {name: ""}, user: {}}
  }

  describe "POST #create" do
    before { allow(AdminMailer).to receive_message_chain(:registration_request, :deliver_later) }
    context "with valid params" do

      shared_examples "with valid params" do
        before { post :create, params: { registration_request: valid_attributes } }
        it { expect(RegistrationRequest.count).to eq(1) }
        it { expect(response.status).to eq(201) }
        it { expect(JSON.parse(response.body)).to have_key("registration_request") }
        it { expect(AdminMailer).to have_received(:registration_request).with(RegistrationRequest.last.id).once }
      end

      context "for a new user" do
        include_examples "with valid params"
      end

      context "for an existing user" do
        before { create :public_user, phone: "0612345678", first_name: nil, last_name: nil, email: nil }
        include_examples "with valid params"
      end
    end

    context "with invalid params" do
      before { post :create, params: { registration_request: invalid_attributes } }
      it { expect(RegistrationRequest.count).to eq(0) }
      it { expect(response.status).to eq(400) }
      it { expect(JSON.parse(response.body)).to eq({"errors"=>{"organization"=>["Nom doit être rempli(e)", "Adresse doit être rempli(e)"], "user"=>["Téléphone doit être rempli(e)", "Téléphone devrait être au format +33... ou 06...", "Prénom doit être rempli(e)", "Nom doit être rempli(e)", "Email doit être rempli(e)", "Association de maraude n'est pas valide"]}}) }
    end
  end
end
