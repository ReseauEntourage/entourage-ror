require 'rails_helper'
include AuthHelper
include CommunityHelper

RSpec.describe Api::V1::UsersController, :type => :controller do
  render_views

  let(:result) { JSON.parse(response.body) }

  describe 'POST #login' do
    before { ENV["DISABLE_CRYPT"]="FALSE" }
    after { ENV["DISABLE_CRYPT"]="TRUE" }

    context 'when the user exists' do
      let!(:user) { create :pro_user, sms_code: "123456", avatar_key: "avatar" }
      let(:partner) { create :partner }
      before { UserPartner.create!(user: user, partner: partner, default: true) }

      context 'when the phone number and sms code are valid' do
        before { post 'login', user: {phone: user.phone, sms_code: "123456"}, format: 'json' }
        it { expect(response.status).to eq(200) }

        it "renders user" do
          expect(result).to eq({"user"=>
                                 {"id"=>user.id,
                                  "email"=>user.email,
                                  "display_name"=>"John D",
                                  "first_name"=> "John",
                                  "last_name"=> "Doe",
                                  "about"=> nil,
                                  "token"=>user.token,
                                  "user_type"=>"pro",
                                  "avatar_url"=>"https://foobar.s3-eu-west-1.amazonaws.com/300x300/avatar.jpg",
                                  "organization"=>{"name"=>user.organization.name,
                                                   "description"=>"Association description",
                                                   "phone"=>user.organization.phone,
                                                   "address"=>user.organization.address,
                                                   "logo_url"=>nil},
                                  "stats"=>{
                                      "tour_count"=>0,
                                      "encounter_count"=>0,
                                      "entourage_count"=>0,
                                  },
                                  "partner"=>{
                                      "id"=>partner.id,
                                      "name"=>"MyString",
                                      "large_logo_url"=>"MyString",
                                      "small_logo_url"=>"MyString",
                                      "description"=>"MyDescription",
                                      "phone"=>nil,
                                      "address"=>nil,
                                      "website_url"=>nil,
                                      "email"=>nil,
                                      "default"=>true
                                  }
                                 }})
        end
      end

      context 'invalid sms code' do
        before { post 'login', user: {phone: user.phone, sms_code: "invalid code"}, format: 'json' }
        it { expect(response.status).to eq(401) }
        it { expect(result).to eq({"error"=>{"code"=>"UNAUTHORIZED", "message" => "wrong phone / sms_code"}}) }
      end

      context 'invalid phone number format' do
        before { post 'login', user: {phone: "1234x"}, format: 'json' }
        it { expect(response.status).to eq(401) }
        it { expect(result).to eq({"error"=>{"code"=>"INVALID_PHONE_FORMAT", "message"=>"invalid phone number format"}}) }
      end
    end
    context 'when user does not exist' do
      context 'using the email' do
        before { post 'login', user: {email: 'not_existing@nowhere.com', sms_code: 'sms code'}, format: 'json' }
        it { expect(response.status).to eq(401) }
      end
      context 'using the phone number and sms code' do
        before { post 'login', user: {phone: 'phone', sms_code: 'sms code'}, format: 'json' }
        it { expect(response.status).to eq(401) }
      end
    end
    context 'when user is deleted' do
      let(:deleted_user) { FactoryGirl.create(:pro_user, deleted: true, sms_code: "123456") }
      before { post 'login', user: {phone: deleted_user.phone, sms_code: "123456"}, format: 'json' }
      it { expect(response.status).to eq(401) }
      it { expect(result).to eq({"error"=>{"code"=>"DELETED", "message"=>"user is deleted"}}) }
    end
    context 'when user is not deleted' do
      let(:not_deleted_user) { FactoryGirl.create(:pro_user, deleted: false, sms_code: "123456") }
      before { post 'login', user: {phone: not_deleted_user.phone, sms_code: "123456"}, format: 'json' }
      it { expect(response.status).to eq(200) }
    end
    context "user with tours and encounters" do
      let!(:user) { create :pro_user, sms_code: "123456", validation_status: "validated", avatar_key: "avatar" }
      let!(:tour1) { create :tour, user: user }
      let!(:tour2) { create :tour }
      let!(:tour3) { create :tour, user: user }
      let!(:encounter1) { create :encounter, tour: tour1 }
      let!(:encounter2) { create :encounter, tour: tour1 }
      let!(:encounter3) { create :encounter, tour: tour2 }
      let!(:encounter4) { create :encounter, tour: tour3 }
      let!(:entourage) { create :entourage, user: user }

      before { post 'login', user: {phone: user.phone, sms_code: "123456"}, format: 'json' }
      it { expect(JSON.parse(response.body)).to eq({"user"=>{"id"=>user.id,
                                                             "email"=>user.email,
                                                             "display_name"=>"John D",
                                                             "first_name"=> "John",
                                                             "last_name"=> "Doe",
                                                             "about" => nil,
                                                             "user_type"=>"pro",
                                                             "token"=>user.token,
                                                             "avatar_url"=>"https://foobar.s3-eu-west-1.amazonaws.com/300x300/avatar.jpg",
                                                             "organization"=>{"name"=>user.organization.name,
                                                                              "description"=>"Association description",
                                                                              "phone"=>user.organization.phone,
                                                                              "address"=>user.organization.address,
                                                                              "logo_url"=>nil},
                                                             "stats"=>{
                                                                 "tour_count"=>2,
                                                                 "encounter_count"=>3,
                                                                 "entourage_count"=>1,
                                                             },
                                                             "partner"=>nil}}) }
    end

    context "blocked user" do
      let!(:user) { create :pro_user, sms_code: "123456", validation_status: "blocked", avatar_key: nil }
      before { post 'login', user: {phone: user.phone, sms_code: "123456"}, format: 'json' }
      it { expect(response.status).to eq(401) }
      it { expect(result).to eq({"error"=>{"code"=>"DELETED", "message"=>"user is deleted"}}) }
    end

    context "no avatar" do
      let!(:user) { create :pro_user, sms_code: "123456", validation_status: "validated", avatar_key: nil }
      before { post 'login', user: {phone: user.phone, sms_code: "123456"}, format: 'json' }
      it { expect(JSON.parse(response.body)["user"]["avatar_url"]).to be_nil }
    end

    context "public user with version 1.2.0" do
      before { ApiRequest.any_instance.stub(:key_infos) { {version: "1.2.0", community: 'entourage'} } }
      let!(:user) { create :public_user, sms_code: "123456"}
      before { post 'login', user: {phone: user.phone, sms_code: "123456"}, format: 'json' }
      it { expect(response.status).to eq(200) }
    end

    context "apple formatted phone number" do
      let!(:user) { create :public_user, phone: "+40724593579", sms_code: "123456"}
      before { post 'login', user: {phone: "+40 (724) 593 579", sms_code: "123456"}, format: 'json' }
      it { expect(response.status).to eq(200) }
    end
  end

  describe 'PATCH update' do
    let!(:user) { create :pro_user, avatar_key: "avatar" }

    context 'authentication is OK' do
      before { ENV["DISABLE_CRYPT"]="FALSE" }
      after { ENV["DISABLE_CRYPT"]="TRUE" }

      context 'params are valid' do
        before { patch 'update', token:user.token, user: { email:'new@e.mail', sms_code:'654321', device_id: 'foo', device_type: 'android', avatar_key: 'foo.jpg'}, format: :json }
        it { expect(response.status).to eq(200) }
        it { expect(user.reload.email).to eq('new@e.mail') }
        it { expect(user.reload.avatar_key).to eq('foo.jpg') }
        it { expect(BCrypt::Password.new(User.find(user.id).sms_code) == '654321').to be true }

        it "renders user" do
          expect(JSON.parse(response.body)["user"]["id"]).to eq(user.id)
        end
      end

      context 'try to update phone number' do
        before { patch 'update', token:user.token, user: { phone:'+33654876754' }, format: :json }
        it { expect(response.status).to eq(400) }
      end

      context 'params are invalid' do
        before { patch 'update', token:user.token, user: { email:'bademail', sms_code:'badcode' }, format: :json }
        it { expect(response.status).to eq(400) }
        it { expect(result).to eq({"error"=>{"code"=>"CANNOT_UPDATE_USER", "message"=>["Email n'est pas valide"]}}) }
      end

      context 'about is too long' do
        before { patch 'update', token:user.token, user: { about: "x" * 201 }, format: :json }
        it { expect(response.status).to eq(400) }
        it { expect(result).to eq({"error"=>{"code"=>"CANNOT_UPDATE_USER", "message"=>["À propos est trop long (pas plus de 200 caractères)"]}}) }
      end
    end

    context 'bad authentication' do
      before { patch 'update', token:'badtoken', user: { email:'new@e.mail', sms_code:'654321' }, format: :json }
      it { expect(response.status).to eq(401) }
    end

    describe "upload avatar" do
      let(:avatar) { fixture_file_upload('avatar.jpg', 'image/jpeg') }

      context "valid params" do
        it "sets user avatar key" do
          patch 'update', token:user.token, user: { avatar: avatar }, format: :json
          expect(user.reload.avatar_key).to eq("avatar")
        end
      end
    end

    describe "welcome email" do
      context "user has no email" do
        let!(:user) { create :public_user, email: nil }
        before { expect_any_instance_of(MemberMailer).to receive(:welcome).once }
        it { patch 'update', token: user.token, user: { email:'new@e.mail' }, format: :json }
      end

      context "user has an email" do
        let!(:user) { create :public_user, email: "foo@bar.com" }
        before { expect_any_instance_of(MemberMailer).to receive(:welcome).never }
        it { patch 'update', token: user.token, user: { email:'new@e.mail' }, format: :json }
      end
    end
  end

  describe 'code' do
    let!(:user) { create :pro_user, sms_code: "123456", avatar_key: "avatar" }

    describe "regenerate sms code" do
      before { patch 'code', {id: "me", user: { phone: user.phone }, code: {action: "regenerate"}, format: :json} }
      it { expect(response.status).to eq(200) }
      it { expect(user.reload.sms_code).to_not eq("123456") }
      it "renders user" do
        expect(JSON.parse(response.body)["user"]["id"]).to eq(user.id)
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

  describe "POST create" do
    it "creates a new user" do
      expect {
        post 'create', {user: {phone: "+33612345678"}}
      }.to change { User.count }.by(1)
    end

    context "valid params" do
      before { post 'create', {user: {phone: "+33612345678"}} }
      it { expect(User.last.user_type).to eq("public") }
      it { expect(User.last.community).to eq("entourage") }
      it { expect(User.last.phone).to eq("+33612345678") }
      it { expect(JSON.parse(response.body)["user"]["id"]).to eq(User.last.id) }

      context "community support" do
        with_community :pfp
        it { expect(User.last.community).to eq("pfp") }
      end
    end

    context "already has a user without email" do
      let!(:previous_user) { FactoryGirl.create(:public_user, email: nil) }
      before { post 'create', {user: {phone: "+33612345678"}} }
      it { expect(response.status).to eq(201) }
    end

    context "user with Apple formated phone number" do
      before { post 'create', {user: {phone: "+40 (724) 593 579"}} }
      it { expect(User.last.phone).to eq("+40724593579") }
    end

    context "invalid params" do
      it "doesn't create a new user" do
        expect {
          post 'create', {user: {phone: "123"}}
        }.to change { User.count }.by(0)
      end

      it "returns error" do
        post 'create', {user: {phone: "123"}}
        user = User.last
        expect(response.status).to eq(400)
        expect(result).to eq({"error"=>{"code"=>"INVALID_PHONE_FORMAT", "message"=>"Phone devrait être au format +33... ou 06..."}})
      end
    end

    context "phone already exists" do
      let!(:existing_user) { FactoryGirl.create(:public_user, phone: "+33612345678") }
      before { post 'create', {user: {phone: "+33612345678"}} }
      it { expect(User.count).to eq(1) }
      it { expect(response.status).to eq(400) }
      it { expect(result).to eq({"error"=>{"code"=>"PHONE_ALREADY_EXIST", "message"=>"Phone +33612345678 n'est pas disponible"}}) }
    end
  end

  describe 'GET show' do
    let!(:user) { create :pro_user}
    let(:partner) { create :partner }
    before { UserPartner.create!(user: user, partner: partner, default: true) }

    context "not signed in" do
      before { get :show, id: user.id }
      it { expect(response.status).to eq(401) }
    end

    context "user signed in" do
      context "get your own profile" do
        before { get :show, id: user.id, token: user.token }
        it { expect(response.status).to eq(200) }
        it { expect(JSON.parse(response.body)).to eq({"user"=>
                                                          {"id"=>user.id,
                                                           "email"=>user.email,
                                                           "display_name"=>"John D",
                                                           "first_name"=>"John",
                                                           "last_name"=>"Doe",
                                                           "about"=>nil,
                                                           "token"=>user.token,
                                                           "user_type"=>"pro",
                                                           "avatar_url"=>nil,
                                                           "organization"=>{"name"=>user.organization.name,
                                                                            "description"=>"Association description",
                                                                            "phone"=>user.organization.phone,
                                                                            "address"=>user.organization.address,
                                                                            "logo_url"=>nil},
                                                           "stats"=>{
                                                               "tour_count"=>0,
                                                               "encounter_count"=>0,
                                                               "entourage_count"=>0,
                                                           },
                                                           "partner"=>{
                                                               "id"=>partner.id,
                                                               "name"=>"MyString",
                                                               "large_logo_url"=>"MyString",
                                                               "small_logo_url"=>"MyString",
                                                               "description"=>"MyDescription",
                                                               "phone"=>nil,
                                                               "address"=>nil,
                                                               "website_url"=>nil,
                                                               "email"=>nil,
                                                               "default"=>true
                                                           }}}) }
      end

      context "get my profile with 'me' shortcut" do
        before { get :show, id: "me", token: user.token }
        it { expect(response.status).to eq(200) }
        it { expect(JSON.parse(response.body)).to eq({"user"=>
                                                          {"id"=>user.id,
                                                           "email"=>user.email,
                                                           "display_name"=>"John D",
                                                           "first_name"=>"John",
                                                           "last_name"=>"Doe",
                                                           "about"=>nil,
                                                           "token"=>user.token,
                                                           "user_type"=>"pro",
                                                           "avatar_url"=>nil,
                                                           "organization"=>{"name"=>user.organization.name, "description"=>"Association description", "phone"=>user.organization.phone, "address"=>user.organization.address, "logo_url"=>nil},
                                                           "stats"=>{
                                                               "tour_count"=>0,
                                                               "encounter_count"=>0,
                                                               "entourage_count"=>0,
                                                           },
                                                           "partner"=>{
                                                               "id"=>partner.id,
                                                               "name"=>"MyString",
                                                               "large_logo_url"=>"MyString",
                                                               "small_logo_url"=>"MyString",
                                                               "description"=>"MyDescription",
                                                               "phone"=>nil,
                                                               "address"=>nil,
                                                               "website_url"=>nil,
                                                               "email"=>nil,
                                                               "default"=>true
                                                           }}}) }
      end

      context "get someone else profile" do
        let(:other_user) { FactoryGirl.create(:pro_user, about: "about") }
        before { get :show, id: other_user.id, token: user.token }
        it { expect(response.status).to eq(200) }
        it { expect(JSON.parse(response.body)).to eq({"user"=>
                                                          {"id"=>other_user.id,
                                                           "display_name"=>"John D",
                                                           "first_name"=>"John",
                                                           "last_name"=>"Doe",
                                                           "about"=>"about",
                                                           "avatar_url"=>nil,
                                                           "user_type"=>"pro",
                                                           "organization"=>{"name"=>other_user.organization.name, "description"=>"Association description", "phone"=>other_user.organization.phone, "address"=>other_user.organization.address, "logo_url"=>nil},
                                                           "stats"=>{
                                                               "tour_count"=>0,
                                                               "encounter_count"=>0,
                                                               "entourage_count"=>0,
                                                           },
                                                           "partner"=>nil}}) }
      end
    end
  end

  describe "DELETE destroy" do
    before { Timecop.freeze(Time.parse("10/10/2010").at_beginning_of_day) }
    let!(:user) { FactoryGirl.create(:pro_user, deleted: false, phone: "0612345678", email: "foo@bar.com") }
    before { delete :destroy, id: user.to_param, token: user.token }
    it { expect(user.reload.deleted).to be true }
    it { expect(user.reload.phone).to eq("+33612345678-2010-10-10 00:00:00") }
    it { expect(user.reload.email).to eq("foo@bar.com-2010-10-10 00:00:00") }
    it { expect(response.status).to eq(200) }
  end

  describe 'POST #report' do
    let(:reporting_user) { create :public_user }
    let(:reported_user)  { create :public_user }
    let(:message) { "MESSAGE" }

    before { post 'report', token: reporting_user.token, id: reported_user.id, user_report: {message: message} }

    context "valid params" do
      it { expect(response.status).to eq 201 }
      it { expect(ActionMailer::Base.deliveries.count).to eq 1 }
    end

    context "missing message" do
      let(:message) { '' }
      it { expect(response.status).to eq 400 }
      it { expect(ActionMailer::Base.deliveries.count).to eq 0 }
    end
  end
end
