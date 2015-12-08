require 'rails_helper'
include AuthHelper

RSpec.describe RegistrationRequestsController, type: :controller do
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

  context "authorised method" do
    let!(:user) { admin_basic_login }

    describe "GET #index" do
      context "has registration requests" do
        let!(:pending_registration_requests) { FactoryGirl.create_list(:registration_request, 2, status: "pending") }
        let!(:validated_registration_requests) { FactoryGirl.create_list(:registration_request, 2, status: "validated") }
        before { get :index }
        it { expect(assigns(:registration_requests)).to eq(pending_registration_requests) }
      end

      context "no registration requests" do
        before { get :index }
        it { expect(assigns(:registration_requests)).to eq([]) }
      end
    end

    describe "GET show" do
      let(:registration_request) { FactoryGirl.create(:registration_request) }
      before { get 'show', id: registration_request.to_param }
      it { expect(assigns(:registration_request)).to eq(registration_request) }
      it { should render_template('show') }
    end

    describe "DELETE destroy" do
      let(:registration_request) { FactoryGirl.create(:registration_request) }
      before { delete 'destroy', id: registration_request.to_param }
      it { expect(RegistrationRequest.count).to eq(0) }
      it { should redirect_to registration_requests_path }
    end

    describe "PUT update" do
      let(:registration_request) { FactoryGirl.create(:registration_request, status: "pending") }

      context "validate" do
        before { put 'update', id: registration_request.to_param, validate: true }
        it { expect(registration_request.reload.status).to eq("validated") }
        #Already 1 user authenticated with organization
        it { expect(Organization.count).to eq(2) }
        it { expect(User.count).to eq(2) }
      end

      context "don't validate" do
        before { put 'update', id: registration_request.to_param }
        it { expect(registration_request.reload.status).to eq("pending") }
        #Already 1 user authenticated with organization
        it { expect(Organization.count).to eq(1) }
        it { expect(User.count).to eq(1) }
      end
    end
  end

  context "unauthorised methods" do
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
end
