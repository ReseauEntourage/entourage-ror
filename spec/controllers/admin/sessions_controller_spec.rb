require 'rails_helper'
include AuthHelper

describe Admin::SessionsController do

  describe 'GET logout' do
    let!(:admin) { admin_basic_login }
    before { get :logout }
    it { expect(session[:user_id]).to be nil }
    it { expect(session[:admin_user_id]).to be nil }
  end

  describe 'GET switch_user' do
    context 'not logged in with an admin' do
      before { get :switch_user, params: { id: 2 } }
      it { should redirect_to new_session_path(continue: request.fullpath) }
    end

    context 'admin logged in' do
      let(:another_user) { FactoryBot.create(:pro_user) }
      let!(:admin) { admin_basic_login }
      before { get :switch_user, params: { user_id: another_user.id } }
      it { expect(session[:user_id]).to eq(another_user.id) }
      it { expect(session[:admin_user_id]).to eq(admin.id) }
    end
  end
end
