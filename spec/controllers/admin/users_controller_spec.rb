require 'rails_helper'
include AuthHelper

describe Admin::UsersController do

  let(:validated_user_with_avatar) { FactoryBot.create(:public_user, validation_status: "validated", avatar_key: "avatar_123") }
  let(:validated_user_without_avatar) { FactoryBot.create(:public_user, validation_status: "validated", avatar_key: nil) }
  let(:blocked_user) { FactoryBot.create(:public_user, validation_status: "blocked", avatar_key: "avatar_456") }

  describe 'GET moderate' do
    context "not signed in" do
      before { get :moderate }
      it { should redirect_to new_session_path(continue: request.fullpath) }
    end

    context "signed in" do
      let!(:user) { admin_basic_login }
      before { get :moderate }
      it { expect(response.code).to eq("200") }
      it { expect(assigns(:users)).to eq([validated_user_with_avatar]) }
    end
  end

  describe 'PUT banish' do
    context "not signed in" do
      before { put :banish, params: { id: validated_user_with_avatar.to_param } }
      it { should redirect_to new_session_path }
    end

    context "signed in" do
      let!(:user) { admin_basic_login }
      before(:each) do
        stub_request(:delete, "https://foobar.s3.eu-west-1.amazonaws.com/#{validated_user_with_avatar.avatar_key}").
            to_return(:status => 200, :body => "", :headers => {})
        stub_request(:delete, "https://foobar.s3.eu-west-1.amazonaws.com/300x300/#{validated_user_with_avatar.avatar_key}").
            to_return(:status => 200, :body => "", :headers => {})

        put :banish, params: { id: validated_user_with_avatar.to_param }
      end
      it { should redirect_to moderate_admin_users_path(validation_status: "blocked") }
      it { expect(validated_user_with_avatar.reload.validation_status).to eq("blocked") }
    end
  end

  describe 'PUT validate' do
    context "not signed in" do
      before { put :validate, params: { id: blocked_user.to_param } }
      it { should redirect_to new_session_path }
    end

    context "signed in" do
      let!(:user) { admin_basic_login }
      before { put :validate, params: { id: blocked_user.to_param } }
      it { should redirect_to moderate_admin_users_path(validation_status: "validated") }
      it { expect(blocked_user.reload.validation_status).to eq("validated") }
    end
  end

  describe "experimental_pending_request_reminder" do
    context "signed in" do
      let!(:user) { admin_basic_login }
      before { post :experimental_pending_request_reminder, params: { id: user.to_param } }
      it { should redirect_to root_path }
    end
  end
end
