require 'rails_helper'
include AuthHelper
include Requests::JsonHelpers

RSpec.describe UsersController, :type => :controller do
  render_views
  
  describe 'POST #login' do
    context 'when the user exists' do
      let(:device_id) { 'device_id' }
      let(:device_type) { 'android' }
      let(:user) { create :user }
      context 'when user email is valid' do
        before { post 'login', email: user.email, device_id: device_id, device_type: device_type, format: 'json' }
        it { expect(response.status).to eq(200) }
        it { expect(assigns(:user)).to eq(user) }
        it { expect(User.find(user.id).device_id).to eq(device_id) }
        it { expect(User.find(user.id).device_type).to eq(device_type) }
      end
      context 'when the phone number and sms code are valid' do
        before { post 'login', phone: user.phone, sms_code: user.sms_code, device_id: device_id, device_type: device_type, format: 'json' }
        it { expect(response.status).to eq(200) }
        it { expect(assigns(:user)).to eq(user) }
        it { expect(User.find(user.id).device_id).to eq(device_id) }
        it { expect(User.find(user.id).device_type).to eq(device_type) }
      end
      context 'when sms code is invalid' do
        before { post 'login', phone: user.phone, sms_code: 'wrong sms code', device_id: device_id, device_type: device_type, format: 'json' }
        it { expect(response.status).to eq(400) }
        it { expect(assigns(:user)).to be_nil }
      end
    end
    context 'when user does not exist' do
      context 'using the email' do
        before { post 'login', email: 'not_existing@nowhere.com', format: 'json' }
        it { expect(response.status).to eq(400) }
        it { expect(assigns(:user)).to be_nil }
      end
      context 'using the phone number and sms code' do
        before { post 'login', phone: 'phone', sms_code: 'sms code', format: 'json' }
        it { expect(response.status).to eq(400) }
        it { expect(assigns(:user)).to be_nil }
      end
    end
  end
  
  describe 'get index' do

    context 'without basic authentication' do
      it "retuns 401" do
        get 'index', :format => :json
        expect(response.status).to eq(401)
      end
    end
    
    context 'without any user' do
      it "retuns 200" do
        admin_basic_login
        get 'index', :format => :json
        expect(response.status).to eq(200)
      end

      it "assigns empty array" do
        admin_basic_login
        get 'index', :format => :json
        expect(assigns(:users)).to match_array([])
      end

      it 'returns empty array' do
        admin_basic_login
        get 'index', :format => :json
        expect(json["users"]).to match_array([])
      end

    end

    context 'with one user' do
      it 'assigns array with user' do
        admin_basic_login
        user = FactoryGirl.create(:user)
        get 'index', :format => :json
        expect(assigns(:users)).to match_array([user])
      end

      it 'returns array with one user' do
        admin_basic_login
        user = FactoryGirl.create(:user)
        get 'index', :format => :json
        expect(json["users"]).to match_array([{"id" => user.id,"email"=>user.email,"first_name"=>user.first_name, "last_name"=>user.last_name}])
      end
    end

  end

  describe 'post create' do

    context 'without basic authentication' do
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
      it "retuns 201" do
        admin_basic_login
        post 'create', user: {email: "test@rspec.com", first_name:"tester", last_name:"tested", phone:'+33102030405'}, format: :json
        expect(response.status).to eq(201)
      end

      it "creates new user" do
        admin_basic_login
        user_count = User.count
        post 'create', user: {email: "test@rspec.com", first_name:"tester", last_name:"tested", phone:'+33102030405'}, format: :json
        expect(User.count).to eq(user_count + 1)
      end
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
      it "retuns 200" do
        admin_basic_login
        user = FactoryGirl.create(:user)
        put 'update', id: user.id, user: {email: "change#{user.email}", first_name:"change#{user.first_name}", last_name:"change#{user.last_name}"}, format: :json
        expect(response.status).to eq(200)
      end

      it "changes user attributes" do
        admin_basic_login
        initial_user = FactoryGirl.create(:user)
        put 'update', id: initial_user.id, user: {email: "change#{initial_user.email}", first_name:"change#{initial_user.first_name}", last_name:"change#{initial_user.last_name}"}, format: :json
        changed_user = User.find(initial_user.id)
        expect(changed_user.email).to eq("change#{initial_user.email}")
        expect(changed_user.first_name).to eq("change#{initial_user.first_name}")
        expect(changed_user.last_name).to eq("change#{initial_user.last_name}")
      end
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
  
  describe '#send_message' do
    let!(:user1) { FactoryGirl.create :user }
    let!(:user2) { FactoryGirl.create :user }
    let!(:user3) { FactoryGirl.create :user, device_id: nil }
    let!(:user4) { FactoryGirl.create :user }
    let!(:android_notification_service) { spy('android_notification_service') }
    let!(:sender) { 'sender' }
    let!(:object) { 'object' }
    let!(:content) { 'content' }
    
    before do
      controller.android_notification_service = android_notification_service
      admin_basic_login
      post 'send_message', sender: sender, object: object, content: content, user_ids: [user2.id, user3.id, user4.id], format: :json
    end
    
    it { expect(response.status).to eq(200) }
    it { expect(android_notification_service).to have_received(:send_notification).with(sender, object, content, [user2.device_id, user4.device_id]) }
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
        post 'send_sms', id: user.id + 1, format: :json
      end
      it { expect(response.status).to eq(404) }
    end
  end

end
