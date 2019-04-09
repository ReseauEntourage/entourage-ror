require 'rails_helper'

describe SessionsController do
  render_views

  describe 'GET new' do
    before { get :new }
    it { expect(response.status).to eq(200) }
  end

  describe 'POST create' do
    context "Valid credentials" do
      before { ENV["DISABLE_CRYPT"]="FALSE" }
      after { ENV["DISABLE_CRYPT"]="TRUE" }
      let!(:user) { FactoryGirl.create(:pro_user, phone: "+33612345678", sms_code: "123456") }
      before { post :create, phone: "+33612345678", sms_code: "123456" }
      it { expect(session[:user_id]).to eq(user.id) }
      it { should redirect_to root_url }

      context "login with 06 and phone saved as +33" do
        before { post :create, phone: "0612345678", sms_code: "123456" }
        it { expect(session[:user_id]).to eq(user.id) }
      end
    end

    describe "public user" do
      before { ENV["DISABLE_CRYPT"]="FALSE" }
      after { ENV["DISABLE_CRYPT"]="TRUE" }
      let!(:user) { FactoryGirl.create(:public_user, phone: "+33612345678", sms_code: "123456", admin: false) }
      before { post :create, phone: "+33612345678", sms_code: "123456" }
      it { expect(session[:admin_user_id]).to be_nil }
      it { expect(session[:user_id]).to eq(user.id) }
      it { expect(response).to redirect_to edit_public_user_user_path(user) }
    end

    context "Invalid credentials" do
      before { post :create, phone: "+33612345678", sms_code: "123456" }
      it { expect(session[:user_id]).to be_nil }
      it { should redirect_to new_session_path }

      context "login with wrong 06 and phone saved as +33" do
        let!(:user) { FactoryGirl.create(:pro_user, phone: "+33612345678", sms_code: "123456") }
        before { post :create, phone: "0612345679", sms_code: "123456" }
        it { expect(session[:user_id]).to be_nil }
      end
    end

    describe "admin authent" do
      context "not admin" do
        let!(:user) { FactoryGirl.create(:pro_user, phone: "+33612345678", sms_code: "123456", admin: false) }
        before { post :create, phone: "+33612345678", sms_code: "123456" }
        it { expect(session[:admin_user_id]).to be_nil }
      end

      context "admin" do
        before { ENV["DISABLE_CRYPT"]="FALSE" }
        after { ENV["DISABLE_CRYPT"]="TRUE" }
        let!(:user) { FactoryGirl.create(:pro_user, phone: "+33612345678", sms_code: "123456", admin: true) }
        before { post :create, phone: "+33612345678", sms_code: "123456" }
        it { expect(session[:admin_user_id]).to eq(user.id) }
      end

      context "logout and then login" do
        before { ENV["DISABLE_CRYPT"]="FALSE" }
        after { ENV["DISABLE_CRYPT"]="TRUE" }
        it "doesn't log as admin" do
          admin = FactoryGirl.create(:pro_user, phone: "+33612345678", sms_code: "123456", admin: true)
          post :create, phone: "+33612345678", sms_code: "123456"
          expect(session[:admin_user_id]).to eq(admin.id)

          user = FactoryGirl.create(:pro_user, phone: "+33612345679", sms_code: "123456", admin: false)
          post :create, phone: "+33612345679", sms_code: "123456"
          expect(session[:admin_user_id]).to be_nil
        end
      end
    end
  end

  describe 'DELETE destroy' do
    let!(:user_session) { session[:user_id] = "123" }
    before { delete :destroy, id: "123" }
    it { expect(session[:user_id]).to be_nil }
    it { expect(session[:admin_user_id]).to be_nil }
    it { should redirect_to root_url }
  end
end
