require 'rails_helper'
include AuthHelper
include Requests::JsonHelpers

RSpec.describe Api::V1::UsersController, :type => :controller do
  render_views
  
  describe 'POST #login' do
    context 'when the user exists' do
      before { ENV["DISABLE_CRYPT"]="FALSE" }
      after { ENV["DISABLE_CRYPT"]="TRUE" }
      let!(:device_id) { 'device_id' }
      let!(:device_type) { 'android' }
      let!(:user) { create :user, sms_code: "123456" }
      let!(:tour1) { create :tour, user: user }
      let!(:tour2) { create :tour }
      let!(:tour3) { create :tour, user: user }
      let!(:encounter1) { create :encounter, tour: tour1 }
      let!(:encounter2) { create :encounter, tour: tour1 }
      let!(:encounter3) { create :encounter, tour: tour2 }
      let!(:encounter4) { create :encounter, tour: tour3 }

      context 'when the phone number and sms code are valid' do
        before { post 'login', phone: user.phone, sms_code: "123456", device_id: device_id, device_type: device_type, format: 'json' }
        it { expect(response.status).to eq(200) }
        it { expect(User.find(user.id).device_id).to eq device_id }
        it { expect(User.find(user.id).device_type).to eq device_type }

        it "renders user" do
          res = JSON.parse(response.body)
          expect(res).to eq({"user"=>{"id"=>user.id, "email"=>user.email, "first_name"=>"John", "last_name"=>"Doe", "token"=>user.token, "organization"=>{"name"=>user.organization.name, "description"=>"Association description", "phone"=>user.organization.phone, "address"=>user.organization.address, "logo_url"=>nil}, "stats"=>{"tour_count"=>2, "encounter_count"=>3}}})
        end
      end

      context 'when sms code is invalid' do
        before { post 'login', phone: user.phone, sms_code: 'wrong sms code', device_id: device_id, device_type: device_type, format: 'json' }
        it { expect(response.status).to eq(401) }
        it { expect(assigns(:user)).to be_nil }
      end
    end
    context 'when user does not exist' do
      context 'using the email' do
        before { post 'login', email: 'not_existing@nowhere.com', sms_code: 'sms code', format: 'json' }
        it { expect(response.status).to eq(401) }
        it { expect(assigns(:user)).to be_nil }
      end
      context 'using the phone number and sms code' do
        before { post 'login', phone: 'phone', sms_code: 'sms code', format: 'json' }
        it { expect(response.status).to eq(401) }
        it { expect(assigns(:user)).to be_nil }
      end
    end
  end

  describe '#updateme' do
    context 'authentication is OK' do
      before { ENV["DISABLE_CRYPT"]="FALSE" }
      after { ENV["DISABLE_CRYPT"]="TRUE" }
      let!(:user) { create :user }

      context 'params are valid' do
        before { patch 'update_me', token:user.token, user: { email:'new@e.mail', sms_code:'654321' }, format: :json }
        it { expect(response.status).to eq(200) }
        it { expect(User.find(user.id).email).to eq('new@e.mail') }
        it { expect(BCrypt::Password.new(User.find(user.id).sms_code) == '654321').to be true }

        it "renders user" do
          res = JSON.parse(response.body)
          expect(res).to eq({"user"=>{"id"=>user.id, "email"=>"new@e.mail", "first_name"=>"John", "last_name"=>"Doe", "token"=>user.token, "organization"=>{"name"=>user.organization.name, "description"=>"Association description", "phone"=>user.organization.phone, "address"=>user.organization.address, "logo_url"=>nil}, "stats"=>{"tour_count"=>0, "encounter_count"=>0}}})
        end
      end

      context 'params are invalid' do
        before { patch 'update_me', token:user.token, user: { email:'bademail', sms_code:'badcode' }, format: :json }
        it { expect(response.status).to eq(400) }
      end
    end

    context 'bad authentication' do
      before { patch 'update_me', token:'badtoken', user: { email:'new@e.mail', sms_code:'654321' }, format: :json }
      it { expect(response.status).to eq(401) }
    end
  end

  describe 'code' do
    let!(:user) { create :user, sms_code: "123456" }

    describe "regenerate sms code" do
      before { patch 'code', {id: "me", user: { phone: user.phone }, code: {action: "regenerate"}, format: :json} }
      it { expect(response.status).to eq(200) }
      it { expect(user.reload.sms_code).to_not eq("123456") }
      it "renders user" do
        res = JSON.parse(response.body)
        expect(res).to eq({"user"=>{"id"=>user.id, "email"=>user.email, "first_name"=>"John", "last_name"=>"Doe", "token"=>user.token, "organization"=>{"name"=>user.organization.name, "description"=>"Association description", "phone"=>user.organization.phone, "address"=>user.organization.address, "logo_url"=>nil}, "stats"=>{"tour_count"=>0, "encounter_count"=>0}}})
      end
    end

    describe "missing phone" do
      before { patch 'code', {id: "me", user: { foo: "bar" }, code: {action: "regenerate"}, format: :json} }
      it { expect(response.status).to eq(400) }
    end

    describe "unknown phone" do
      it "returns 404" do
        expect {
          patch 'code', {id: "me", user: { phone: "0000" }, code: {action: "regenerate"}, format: :json}
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe "unknown action" do
      before { patch 'code', {id: "me", user: { phone: user.phone }, code: {action: "foo"}, format: :json} }
      it { expect(response.status).to eq(400) }
    end
  end

end
