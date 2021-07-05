require 'rails_helper'
include AuthHelper

describe Admin::UsersSearchController do
  let(:user) { FactoryBot.create(:public_user) }

  describe 'GET user_search' do
    context "not signed in" do
      before { get :user_search }
      it { should redirect_to new_session_path(continue: request.fullpath) }
    end

    context "signed in" do
      let!(:user) { admin_basic_login }
      before { get :user_search }
      it { expect(response.code).to eq("200") }
    end
  end

end
