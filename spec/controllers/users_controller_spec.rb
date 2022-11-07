require 'rails_helper'
include AuthHelper
include Requests::JsonHelpers

RSpec.describe UsersController, :type => :controller do
  render_views

  describe 'GET index' do
    context 'not logged in as admin' do
      before { get :index }
      it { should redirect_to new_session_path(continue: request.fullpath) }
    end

    context "logged in as admin" do
      let!(:user) { manager_basic_login }
      let!(:user_outside_organization) { FactoryBot.create(:pro_user) }
      let!(:user_inside_organization) { FactoryBot.create(:pro_user, organization: user.organization) }
      before { get :index }
      it { expect(assigns(:users)).to match_array([user, user_inside_organization]) }
    end
  end

  describe 'GET edit' do
    context 'not logged in as admin' do
      before { get :edit, params: { id: 0 } }
      it { should redirect_to new_session_path(continue: request.fullpath) }
    end

    context 'logged in as admin' do
      let!(:user) { manager_basic_login }
      before { get :edit, params: { id: user.id } }
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
          post 'create', params: { user: {key: "value"} }
          expect(response.status).to eq(200)
          expect(response).to render_template('index')
          expect(User.count).to eq(1)
        end
      end

      context 'with correct parameters' do
        let(:sms_service) { spy }
        before do
          allow(SmsNotificationService).to receive(:new).and_return(sms_service)
        end
        subject do
          post 'create', params: { user: {email: "test@rspec.com", first_name:"tester", last_name:"tested", phone:'+33602030405'}, send_sms: '1' }
        end

        context 'for a new user' do
          before { subject }
          it { expect(response.status).to eq(302) }
          it { expect(User.last.first_name).to eq "tester" }
          it { expect(User.last.last_name).to eq "tested" }
          it { expect(User.last.phone).to eq "+33602030405" }
          it { expect(User.last.email).to eq "test@rspec.com" }
          it { expect(User.last.organization).to eq user.organization }
          it { expect(sms_service).to have_received(:send_notification) }
        end

        context 'for an existing user' do
          before do
            create :public_user, phone: "+33602030405", first_name: "existing", last_name: nil, email: nil
            subject
          end
          it { expect(response.status).to eq(302) }
          it { expect(User.last.first_name).to eq "existing" }
          it { expect(User.last.last_name).to eq "tested" }
          it { expect(User.last.phone).to eq "+33602030405" }
          it { expect(User.last.email).to eq "test@rspec.com" }
          it { expect(User.last.organization).to eq user.organization }
          it { expect(sms_service).to_not have_received(:send_notification) }
        end
      end

      it "doesn't sends sms" do
        expect_any_instance_of(SmsNotificationService).to_not receive(:send_notification)
        post 'create', params: { user: {email: "test@rspec.com", first_name:"tester", last_name:"tested", phone:'+33602030405'}, send_sms: "0" }
      end

      context 'with incorrect parameters' do
        let!(:user_already_exist) { FactoryBot.create(:pro_user, phone: '+33602030405') }
        it "never sends sms" do
          expect_any_instance_of(SmsNotificationService).to_not receive(:send_notification)
          post 'create', params: { user: {email: "test@rspec.com", first_name:"tester", last_name:"tested", phone:'+33602030405'}, send_sms: "1" }
        end
      end
    end
  end


  describe 'put update' do
    context 'with incorrect user id' do
      it "retuns 404" do
        admin_basic_login
        expect {
          put 'update', params: { id: 1, user: {key: "value"} }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "logged in" do
      let!(:user) { admin_basic_login }

      context 'with correct user id and parameters' do
        before do
          put 'update', params: { id: user.id, user: {email: "change#{user.email}", first_name:"change#{user.first_name}", last_name:"change#{user.last_name}"} }
        end

        it { expect(response.status).to eq(302) }
        it { expect(User.find(user.id).first_name).to eq "change#{user.first_name}" }
        it { expect(User.find(user.id).last_name).to eq "change#{user.last_name}" }
        it { expect(User.find(user.id).email).to eq "change#{user.email}" }
        it { expect(User.find(user.id).organization).to eq user.organization }
      end
    end
  end

  describe 'delete destroy' do

    context 'with incorrect user id' do
      it "retuns 404" do
        admin_basic_login
        expect {
          delete 'destroy', params: { id: 1 }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with correct user id' do
      it "Redirects" do
        user = admin_basic_login
        delete 'destroy', params: { id: user.id }
        expect(response.status).to eq(302)
      end

      it "removes the user from the organization and disable it's pro features" do
        admin = admin_basic_login
        user = create :pro_user, organization: admin.organization
        delete 'destroy', params: { id: user.id }
        deleted_user = User.find_by(id: user.id)
        expect(deleted_user.organization_id).to eq(nil)
        expect(deleted_user.user_type).to eq('public')
      end
    end

  end

  describe '#send_sms' do
    let!(:user) { admin_basic_login }
    let!(:target_user) { FactoryBot.create(:pro_user, organization: user.organization) }

    context 'the user exists' do
      before { post 'send_sms', params: { id: target_user.id } }
      it { expect(response.status).to eq(302) }

      it "sends sms" do
        UserServices::SmsCode.any_instance.stub(:code) { "666666" }
        expect_any_instance_of(SmsNotificationService).to receive(:send_notification).with(target_user.phone, "666666 est votre code de connexion Entourage. Bienvenue dans le réseau solidaire.", 'regenerate')
        post 'send_sms', params: { id: target_user.id }
      end
    end

    context 'the user does not exists' do
      it "retuns 404" do
        expect {
          post 'send_sms', params: { id: 0 }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

end
