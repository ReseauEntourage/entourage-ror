require 'rails_helper'
include AuthHelper

RSpec.describe Admin::RegistrationRequestsController, type: :controller do
  render_views

  before { ModerationServices.stub(:moderator) { nil } }
  let!(:user) { admin_basic_login }

  describe "GET #index" do
    context "has registration requests" do
      let!(:pending_registration_requests) { FactoryBot.create_list(:registration_request, 2, status: "pending") }
      let!(:validated_registration_requests) { FactoryBot.create_list(:registration_request, 2, status: "validated") }
      before { get :index }
      it { expect(assigns(:registration_requests)).to eq(pending_registration_requests) }
    end

    context "no registration requests" do
      before { get :index }
      it { expect(assigns(:registration_requests)).to eq([]) }
    end
  end

  describe "GET show" do
    let(:registration_request) { FactoryBot.create(:registration_request) }

    context "valid registration request" do
      before { get 'show', params: { id: registration_request.to_param } }
      it { expect(assigns(:registration_request)).to eq(registration_request) }
      it { should render_template('show') }
    end

    context "empty logo" do
      before do
        RegistrationRequest.any_instance.stub(:organization_field).and_call_original
        RegistrationRequest.any_instance.stub(:organization_field).with("logo_key") { "" }
      end
      before { get 'show', params: { id: registration_request.to_param } }
      it { expect(response.status).to eq(200) }
    end
  end

  describe "DELETE destroy" do
    let(:registration_request) { FactoryBot.create(:registration_request, status: "pending") }
    before { delete 'destroy', params: { id: registration_request.to_param } }
    it { expect(RegistrationRequest.count).to eq(1) }
    it { expect(registration_request.reload.status).to eq("rejected") }
    it { should redirect_to admin_registration_requests_path }
  end

  describe "PUT update" do
    let(:registration_request) { FactoryBot.create(:registration_request, status: "pending") }

    context "validate" do
      shared_examples "validate" do
        describe "objects creation" do
          before do
            put 'update', params: { id: registration_request.to_param, validate: true }
          end
          it { expect(registration_request.reload.status).to eq("validated") }
          #Already 1 user authenticated with organization
          it { expect(Organization.count).to eq(2) }
          it { expect(User.type_pro.count).to eq(2) }
        end
      end

      context "for a new user" do
        include_examples "validate"
      end

      context "with an existing user" do
        before { create :public_user, phone: registration_request.user_field('phone'), first_name: nil, last_name: nil, email: nil }
        include_examples "validate"
      end
    end

    context "don't validate" do
      before { put 'update', params: { id: registration_request.to_param } }
      it { expect(registration_request.reload.status).to eq("pending") }
      #Already 1 user authenticated with organization
      it { expect(Organization.count).to eq(1) }
      it { expect(User.count).to eq(1) }
    end
  end
end
