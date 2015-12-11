require 'rails_helper'
include AuthHelper
include Requests::JsonHelpers

RSpec.describe Api::V0::UsersController, :type => :controller do
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
