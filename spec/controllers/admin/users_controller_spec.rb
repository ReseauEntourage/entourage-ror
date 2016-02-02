require 'rails_helper'
include AuthHelper

describe Admin::UsersController do
  
  describe 'GET moderate' do
    context "not signed in" do
      before { get :moderate }
      it { expect(response.code).to eq("302") }
    end

    context "signed in" do
      let!(:user) { admin_basic_login }
      let(:validated_user_with_avatar) { FactoryGirl.create(:public_user, validation_status: "validated", avatar_key: "avatar_123") }
      let(:validated_user_without_avatar) { FactoryGirl.create(:public_user, validation_status: "validated", avatar_key: nil) }
      let(:blocked_user) { FactoryGirl.create(:public_user, validation_status: "blocked", avatar_key: "avatar_456") }
      before { get :moderate }
      it { expect(response.code).to eq("200") }
      it { expect(assigns(:users)).to eq([validated_user_with_avatar]) }
    end
  end
end