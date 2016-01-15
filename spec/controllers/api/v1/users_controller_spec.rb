require 'rails_helper'
include AuthHelper
include Requests::JsonHelpers

RSpec.describe Api::V1::UsersController, :type => :controller do
  render_views
  
  describe 'POST #login' do
    before { ENV["DISABLE_CRYPT"]="FALSE" }
    after { ENV["DISABLE_CRYPT"]="TRUE" }

    context 'when the user exists' do
      let!(:user) { create :user, sms_code: "123456" }

      context 'when the phone number and sms code are valid' do
        before { post 'login', user: {phone: user.phone, sms_code: "123456"}, format: 'json' }
        it { expect(response.status).to eq(200) }

        it "renders user" do
          res = JSON.parse(response.body)
          expect(res).to eq({"user"=>{"id"=>user.id, "email"=>user.email, "first_name"=>"John", "last_name"=>"Doe", "token"=>user.token, "organization"=>{"name"=>user.organization.name, "description"=>"Association description", "phone"=>user.organization.phone, "address"=>user.organization.address, "logo_url"=>nil}, "stats"=>{"tour_count"=>0, "encounter_count"=>0}}})
        end
      end

      context 'when sms code is invalid' do
        before { post 'login', user: {phone: user.phone, sms_code: "invalid code"}, format: 'json' }
        it { expect(response.status).to eq(401) }
        it { expect(assigns(:user)).to be_nil }
      end
    end
    context 'when user does not exist' do
      context 'using the email' do
        before { post 'login', user: {email: 'not_existing@nowhere.com', sms_code: 'sms code'}, format: 'json' }
        it { expect(response.status).to eq(401) }
        it { expect(assigns(:user)).to be_nil }
      end
      context 'using the phone number and sms code' do
        before { post 'login', user: {phone: 'phone', sms_code: 'sms code'}, format: 'json' }
        it { expect(response.status).to eq(401) }
        it { expect(assigns(:user)).to be_nil }
      end
    end
    context "user with tours and encounters" do
      let!(:user) { create :user, sms_code: "123456" }
      let!(:tour1) { create :tour, user: user }
      let!(:tour2) { create :tour }
      let!(:tour3) { create :tour, user: user }
      let!(:encounter1) { create :encounter, tour: tour1 }
      let!(:encounter2) { create :encounter, tour: tour1 }
      let!(:encounter3) { create :encounter, tour: tour2 }
      let!(:encounter4) { create :encounter, tour: tour3 }

      before { post 'login', user: {phone: user.phone, sms_code: "123456"}, format: 'json' }
      it { expect(JSON.parse(response.body)).to eq({"user"=>{"id"=>user.id, "email"=>user.email, "first_name"=>"John", "last_name"=>"Doe", "token"=>user.token, "organization"=>{"name"=>user.organization.name, "description"=>"Association description", "phone"=>user.organization.phone, "address"=>user.organization.address, "logo_url"=>nil}, "stats"=>{"tour_count"=>2, "encounter_count"=>3}}}) }
    end
  end

  describe 'update' do
    context 'authentication is OK' do
      before { ENV["DISABLE_CRYPT"]="FALSE" }
      after { ENV["DISABLE_CRYPT"]="TRUE" }
      let!(:user) { create :user }

      context 'params are valid' do
        before { patch 'update', token:user.token, user: { email:'new@e.mail', sms_code:'654321', device_id: 'foo', device_type: 'android' }, format: :json }
        it { expect(response.status).to eq(200) }
        it { expect(user.reload.email).to eq('new@e.mail') }
        it { expect(BCrypt::Password.new(User.find(user.id).sms_code) == '654321').to be true }
        it { expect(user.reload.device_id).to eq('foo') }
        it { expect(user.reload.device_type).to eq('android') }

        it "renders user" do
          res = JSON.parse(response.body)
          expect(res).to eq({"user"=>{"id"=>user.id, "email"=>"new@e.mail", "first_name"=>"John", "last_name"=>"Doe", "token"=>user.token, "organization"=>{"name"=>user.organization.name, "description"=>"Association description", "phone"=>user.organization.phone, "address"=>user.organization.address, "logo_url"=>nil}, "stats"=>{"tour_count"=>0, "encounter_count"=>0}}})
        end
      end

      context 'params are invalid' do
        before { patch 'update', token:user.token, user: { email:'bademail', sms_code:'badcode' }, format: :json }
        it { expect(response.status).to eq(400) }
      end
    end

    context 'bad authentication' do
      before { patch 'update', token:'badtoken', user: { email:'new@e.mail', sms_code:'654321' }, format: :json }
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
