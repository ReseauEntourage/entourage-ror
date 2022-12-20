require 'rails_helper'

describe SessionsController do
  render_views

  describe 'GET new' do
    before { get :new }
    it { expect(response.status).to eq(200) }
  end

  describe 'DELETE destroy' do
    let!(:user_session) { session[:user_id] = "123" }
    before { delete :destroy, params: { id: "123" } }
    it { expect(session[:user_id]).to be_nil }
    it { expect(session[:admin_user_id]).to be_nil }
    it { should redirect_to root_url }
  end
end
