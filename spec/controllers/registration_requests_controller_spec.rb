require 'rails_helper'
include AuthHelper

RSpec.describe RegistrationRequestsController, type: :controller do
  render_views

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

    context "valid registration request" do
      before { get 'show', id: registration_request.to_param }
      it { expect(assigns(:registration_request)).to eq(registration_request) }
      it { should render_template('show') }
    end

    context "empty logo" do
      before do
        RegistrationRequest.any_instance.stub(:organization_field).and_call_original
        RegistrationRequest.any_instance.stub(:organization_field).with("logo_key") { "" }
      end
      before { get 'show', id: registration_request.to_param }
      it { expect(response.status).to eq(200) }
    end
  end

  describe "DELETE destroy" do
    let(:registration_request) { FactoryGirl.create(:registration_request, status: "pending") }
    before { delete 'destroy', id: registration_request.to_param }
    it { expect(RegistrationRequest.count).to eq(1) }
    it { expect(registration_request.reload.status).to eq("rejected") }
    it { should redirect_to registration_requests_path }
  end

  describe "PUT update" do
    let(:registration_request) { FactoryGirl.create(:registration_request, status: "pending") }

    context "validate" do
      describe "objects creation" do
        before { put 'update', id: registration_request.to_param, validate: true }
        it { expect(registration_request.reload.status).to eq("validated") }
        #Already 1 user authenticated with organization
        it { expect(Organization.count).to eq(2) }
        it { expect(User.count).to eq(2) }
      end

      it "sends mail" do
        expect(MemberMailer).to receive(:registration_request_accepted).once
        put 'update', id: registration_request.to_param, validate: true
      end
    end

    context "don't validate" do
      before { put 'update', id: registration_request.to_param }
      it { expect(registration_request.reload.status).to eq("pending") }
      #Already 1 user authenticated with organization
      it { expect(Organization.count).to eq(1) }
      it { expect(User.count).to eq(1) }
    end

    it "doesn't send mail" do
      expect(MemberMailer).to receive(:registration_request_accepted).never
      put 'update', id: registration_request.to_param
    end
  end
end
