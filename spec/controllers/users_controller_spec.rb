require 'rails_helper'
include AuthHelper
include Requests::JsonHelpers

RSpec.describe UsersController, :type => :controller do
  render_views

  describe 'get index' do

    context 'not logged in as admin' do
      it "retuns 302" do
        get 'index', :format => :json
        expect(response.status).to eq(401)
      end
    end

    context "logged in as admin" do
      before { admin_basic_login }

      context 'without any user' do
        it "retuns 200" do
          get 'index', :format => :json
          expect(response.status).to eq(200)
        end

        it "assigns current admin" do
          get 'index', :format => :json
          expect(assigns(:users)).to match_array(User.where(admin: true))
        end

        it 'returns current admin' do
          get 'index', :format => :json
          admin = User.where(admin: true).first
          expect(json["users"]).to match_array([{"id"=>admin.id, "email"=>admin.email, "first_name"=>admin.first_name, "last_name"=>admin.last_name}])
        end
      end
    end
  end

  describe 'post create' do

    context 'not logged in as admin' do
      it "retuns 401" do
        post 'create', :format => :json
        expect(response.status).to eq(401)
      end
    end

    context 'with incorrect parameters' do
      it "retuns 400" do
        admin_basic_login
        post 'create', user: {key: "value"}, format: :json
        expect(response.status).to eq(400)
      end
    end

    context 'with correct parameters' do
      let!(:organization) { FactoryGirl.create :organization }

      before do
        admin_basic_login
        post 'create', user: {email: "test@rspec.com", first_name:"tester", last_name:"tested", phone:'+33102030405', organization_id:organization.id}, format: :json
      end

      it { should respond_with 201 }
      it { expect(User.last.first_name).to eq "tester" }
      it { expect(User.last.last_name).to eq "tested" }
      it { expect(User.last.phone).to eq "+33102030405" }
      it { expect(User.last.email).to eq "test@rspec.com" }
      it { expect(User.last.organization).to eq organization }
    end

  end


  describe 'put update' do

    context 'with incorrect user id' do
      it "retuns 404" do
        admin_basic_login
        put 'update', id: 1, user: {key: "value"}, format: :json
        expect(response.status).to eq(404)
      end
    end

    context 'with correct user id and parameters' do
      let!(:organization) { FactoryGirl.create :organization }
      let!(:user) { FactoryGirl.create :user }

      before do
        admin_basic_login
        put 'update', id: user.id, user: {email: "change#{user.email}", first_name:"change#{user.first_name}", last_name:"change#{user.last_name}", organization_id:organization.id}, format: :json
      end

      it { should respond_with 200 }
      it { expect(User.find(user.id).first_name).to eq "change#{user.first_name}" }
      it { expect(User.find(user.id).last_name).to eq "change#{user.last_name}" }
      it { expect(User.find(user.id).email).to eq "change#{user.email}" }
      it { expect(User.find(user.id).organization).to eq organization }
    end

  end

  describe 'delete destroy' do

    context 'with incorrect user id' do
      it "retuns 404" do
        admin_basic_login
        delete 'destroy', id: 1, format: :json
        expect(response.status).to eq(404)
      end
    end

    context 'with correct user id' do
      it "retuns 204" do
        admin_basic_login
        user = FactoryGirl.create(:user)
        delete 'destroy', id: user.id, format: :json
        expect(response.status).to eq(204)
      end

      it "destroys user" do
        admin_basic_login
        user = FactoryGirl.create(:user)
        delete 'destroy', id: user.id, format: :json
        deleted_user = User.find_by(id: user.id)
        expect(deleted_user).to eq(nil)
      end
    end

  end

  describe '#send_sms' do
    let!(:user) { FactoryGirl.create :user }
    let!(:sms_notification_service) { spy('sms_notification_service') }

    context 'the user exists' do
      before do
        controller.sms_notification_service = sms_notification_service
        admin_basic_login
        post 'send_sms', id: user.id, format: :json
      end
      it { expect(response.status).to eq(200) }
      it { expect(sms_notification_service).to have_received(:send_notification).with(user.phone, user.sms_code) }
    end

    context 'the user does not exists' do
      before do
        controller.sms_notification_service = sms_notification_service
        admin_basic_login
        post 'send_sms', id: 0, format: :json
      end
      it { expect(response.status).to eq(404) }
    end
  end

end
