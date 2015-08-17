require 'rails_helper'
include AuthHelper
include Requests::JsonHelpers

RSpec.describe UsersController, :type => :controller do
  render_views
  
  describe 'POST #login' do
    context 'when the user exists' do
      let!(:device_id) { 'device_id' }
      let!(:device_type) { 'android' }
      let!(:user) { create :user }
      let!(:tour1) { create :tour, user: user }
      let!(:tour2) { create :tour }
      let!(:tour3) { create :tour, user: user }
      let!(:encounter1) { create :encounter, tour: tour1 }
      let!(:encounter2) { create :encounter, tour: tour1 }
      let!(:encounter3) { create :encounter, tour: tour2 }
      let!(:encounter4) { create :encounter, tour: tour3 }
      context 'when the phone number and sms code are valid' do
        before { post 'login', phone: user.phone, sms_code: user.sms_code, device_id: device_id, device_type: device_type, format: 'json' }
        it { should respond_with 200 }
        it { expect(assigns(:user)).to eq user }
        it { expect(assigns(:tour_count)).to eq 2 }
        it { expect(assigns(:encounter_count)).to eq 3 }
        it { expect(assigns(:user)).to eq user }
        it { expect(User.find(user.id).device_id).to eq device_id }
        it { expect(User.find(user.id).device_type).to eq device_type }
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

  describe '#updateme' do
    context 'authentication is OK' do
      let!(:user) { create :user }
      context 'params are valid' do
        before { patch 'update_me', token:user.token, user: { email:'new@e.mail', sms_code:'654321' }, format: :json }
        it { should respond_with 200 }
        it { expect(User.find(user.id).email).to eq('new@e.mail') }
        it { expect(User.find(user.id).sms_code).to eq('654321') }
      end
      context 'params are invalid' do
        before { patch 'update_me', token:user.token, user: { email:'bademail', sms_code:'badcode' }, format: :json }
        it { should respond_with 400 }
      end
    end
    context 'bad authentication' do
      before { patch 'update_me', token:'badtoken', user: { email:'new@e.mail', sms_code:'654321' }, format: :json }
      it { should respond_with 401 }
    end
  end

end
