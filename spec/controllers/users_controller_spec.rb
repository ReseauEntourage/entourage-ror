require 'rails_helper'
include AuthHelper
include Requests::JsonHelpers

RSpec.describe UsersController, :type => :controller do
  render_views

  describe 'GET index' do
    context 'not logged in as admin' do
      before { get :index }
      it { should redirect_to new_session_path }
    end

    context "logged in as admin" do
      let!(:user) { manager_basic_login }
      let!(:user_outside_organization) { FactoryGirl.create(:user) }
      let!(:user_inside_organization) { FactoryGirl.create(:user, organization: user.organization) }
      before { get :index }
      it { expect(assigns(:users)).to match_array([user, user_inside_organization]) }
    end
  end

  describe 'GET edit' do
    context 'not logged in as admin' do
      before { get :edit, id: 0 }
      it { should redirect_to new_session_path }
    end

    context 'logged in as admin' do
      let!(:user) { manager_basic_login }
      before { get :edit, id: user.id }
      it { should render_template 'edit' }
    end

  end

  describe 'post create' do
    context 'not logged in as admin' do
      before { post 'create' }
      it { should redirect_to new_session_path }
    end

    context "logged in as admin" do
      let!(:user) { manager_basic_login }

      context 'with incorrect parameters' do
        it "retuns 302" do
          post 'create', user: {key: "value"}
          expect(response.status).to eq(200)
          expect(response).to render_template('index')
          expect(User.count).to eq(1)
        end
      end

      context 'with correct parameters' do
        before do
          post 'create', user: {email: "test@rspec.com", first_name:"tester", last_name:"tested", phone:'+33102030405'}
        end

        it { should respond_with 302 }
        it { expect(User.last.first_name).to eq "tester" }
        it { expect(User.last.last_name).to eq "tested" }
        it { expect(User.last.phone).to eq "+33102030405" }
        it { expect(User.last.email).to eq "test@rspec.com" }
        it { expect(User.last.organization).to eq user.organization }
      end

      it "sends sms" do
        expect_any_instance_of(SmsNotificationService).to receive(:send_notification)
        post 'create', user: {email: "test@rspec.com", first_name:"tester", last_name:"tested", phone:'+33102030405'}, send_sms: "1"
      end

      it "doesn't sends sms" do
        expect_any_instance_of(SmsNotificationService).to_not receive(:send_notification)
        post 'create', user: {email: "test@rspec.com", first_name:"tester", last_name:"tested", phone:'+33102030405'}, send_sms: "0"
      end

      context 'with incorrect parameters' do
        let!(:user_already_exist) { FactoryGirl.create(:user, phone: '+33102030405') }
        it "never sends sms" do
          expect_any_instance_of(SmsNotificationService).to_not receive(:send_notification)
          post 'create', user: {email: "test@rspec.com", first_name:"tester", last_name:"tested", phone:'+33102030405'}, send_sms: "1"
        end
      end
    end
  end


  describe 'put update' do
    context 'with incorrect user id' do
      it "retuns 404" do
        admin_basic_login
        expect {
          put 'update', id: 1, user: {key: "value"}
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "logged in" do
      let!(:user) { admin_basic_login }

      context 'with correct user id and parameters' do
        before do
          put 'update', id: user.id, user: {email: "change#{user.email}", first_name:"change#{user.first_name}", last_name:"change#{user.last_name}"}
        end

        it { should respond_with 302 }
        it { expect(User.find(user.id).first_name).to eq "change#{user.first_name}" }
        it { expect(User.find(user.id).last_name).to eq "change#{user.last_name}" }
        it { expect(User.find(user.id).email).to eq "change#{user.email}" }
        it { expect(User.find(user.id).organization).to eq user.organization }
      end

      context 'with snap to road true' do
        before { put 'update', id: user.id, user: {email: "change#{user.email}", first_name:"change#{user.first_name}", last_name:"change#{user.last_name}", snap_to_road: "true"} }
        it {  expect(PreferenceServices::UserDefault.new(user: User.find(user.id)).snap_to_road).to eq true }
      end

      context 'with snap to road true' do
        before { PreferenceServices::UserDefault.new(user: user).snap_to_road = true }
        before { put 'update', id: user.id, user: {email: "change#{user.email}", first_name:"change#{user.first_name}", last_name:"change#{user.last_name}", snap_to_road: "false"} }
        it { expect(PreferenceServices::UserDefault.new(user: User.find(user.id)).snap_to_road).to eq false }
      end

      context 'without snap to road' do
        before { PreferenceServices::UserDefault.new(user: user).snap_to_road = true }
        before { put 'update', id: user.id, user: {email: "change#{user.email}", first_name:"change#{user.first_name}", last_name:"change#{user.last_name}"} }
        it { expect(PreferenceServices::UserDefault.new(user: User.find(user.id)).snap_to_road).to eq false }
      end
    end
  end

  describe 'delete destroy' do

    context 'with incorrect user id' do
      it "retuns 404" do
        admin_basic_login
        expect {
          delete 'destroy', id: 1
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with correct user id' do
      it "Redirects" do
        user = admin_basic_login
        delete 'destroy', id: user.id
        expect(response.status).to eq(302)
      end

      it "destroys user" do
        user = admin_basic_login
        delete 'destroy', id: user.id
        deleted_user = User.find_by(id: user.id)
        expect(deleted_user).to eq(nil)
      end
    end

  end

  describe '#send_sms' do
    let!(:user) { admin_basic_login }
    let!(:target_user) { FactoryGirl.create(:user, organization: user.organization) }

    context 'the user exists' do
      before { post 'send_sms', id: target_user.id }
      it { expect(response.status).to eq(302) }

      it "sends sms" do
        UserServices::UserBuilder.stub(:sms_code) { "666666" }
        expect_any_instance_of(SmsNotificationService).to receive(:send_notification).with(target_user.phone, "Bienvenue sur Entourage. Votre code est 666666. Retrouvez l'application ici : http://foo.bar .")
        post 'send_sms', id: target_user.id
      end
    end

    context 'the user does not exists' do
      it "retuns 404" do
        expect {
          post 'send_sms', id: 0
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

end
