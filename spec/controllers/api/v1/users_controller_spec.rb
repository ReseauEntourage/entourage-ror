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
      let(:partner) { create :partner }
      let!(:user) { create :pro_user, sms_code: "123456", avatar_key: "avatar", partner: partner }

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
                                  "roles"=>[],
                                  "about"=> nil,
                                  "token"=>user.token,
                                  "user_type"=>"pro",
                                  "has_password"=>false,
                                  "address"=>nil,
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
                                    "small_logo_url"=>"https://s3-eu-west-1.amazonaws.com/entourage-ressources/check-small.png",
                                    "description"=>"MyDescription",
                                    "phone"=>nil,
                                    "address"=>nil,
                                    "website_url"=>nil,
                                    "email"=>nil,
                                    "default"=>true},
                                  "memberships"=>[],
                                  "conversation"=>{"uuid"=>"1_list_#{user.id}"}
                                 }})
        end
      end

      describe "first_sign_in_at" do
        subject { post 'login', user: {phone: user.phone, sms_code: "123456"} }

        context "on the first login" do
          let(:time) { Time.zone.now.change(sec: 0) }
          before { Timecop.freeze(time) }
          before { subject }
          it { expect(user.reload.first_sign_in_at).to eq time }
        end

        context "on subsequent logins" do
          let(:time) { 1.week.ago.change(sec: 0) }
          before { user.update_column(:first_sign_in_at, time) }
          before { subject }
          it { expect(user.reload.first_sign_in_at).to eq time }
        end
      end

      context 'invalid sms code' do
        before { post 'login', user: {phone: user.phone, sms_code: "invalid code"}, format: 'json' }
        it { expect(response.status).to eq(401) }
        it { expect(result).to eq({"error"=>{"code"=>"UNAUTHORIZED", "message" => "wrong phone / sms_code"}}) }
      end

      describe "sms_code / password logic" do
        def login params
          post 'login', user: {phone: user.phone}.merge(params)
          OpenStruct.new(status: response.status, body: JSON.parse(response.body))
        end

        context "when the user doesn't have a password" do
          it { expect(login(sms_code: "123456").status).to eq 200 }
          it { expect(login(sms_code: "123456").body['user']['has_password']).to eq false }
        end

        context "when the user has a password" do
          before { user.update_attributes(password: "P@ssw0rd") }

          context "on the web" do
            before { @request.env['X-API-KEY'] = 'api_debug_web' }
            it { expect(login(secret: "P@ssw0rd").status).to eq 200 }
            it { expect(login(secret: "P@ssw0rd").body['user']['has_password']).to eq true }
            it { expect(login(secret: "123456"  ).status).to eq 401 }
          end

          context "on mobile" do
            it { expect(login(sms_code: "P@ssw0rd").status).to eq 200 }
            it { expect(login(sms_code: "P@ssw0rd").body['user']['has_password']).to eq true }
            it { expect(login(sms_code: "123456"  ).status).to eq 200 }
          end
        end
      end

      context 'invalid phone number format' do
        before { post 'login', user: {phone: "1234x"}, format: 'json' }
        it { expect(response.status).to eq(401) }
        it { expect(result).to eq({"error"=>{"code"=>"INVALID_PHONE_FORMAT", "message"=>"invalid phone number format"}}) }
      end

      context 'auth_token' do
        let(:token_expiration) { 24.hours.from_now }
        let(:token_user_id) { user.id }
        let(:token_payload) { "#{token_user_id}-#{token_expiration.to_i}" }
        let(:token_signature) { SignatureService.sign(token_payload, salt: user.token) }
        let(:token) { "1_#{token_payload}-#{token_signature}" }

        before { post 'login', user: {auth_token: token} }

        context "valid token" do
          it { expect(response.status).to eq(200) }
          it { expect(result['user']['id']).to eq user.id }
        end

        context "expired token" do
          let(:token_expiration) { 1.second.ago }
          it { expect(response.status).to eq(401) }
          it { expect(result['error']['message']).to eq 'invalid auth_token' }
        end

        context "user doesn't exist" do
          let(:token_user_id) { 0 }
          it { expect(response.status).to eq(401) }
          it { expect(result['error']['message']).to eq 'invalid auth_token' }
        end

        context "user doesn't exist" do
          let(:token_signature) { 'wrong_signature' }
          it { expect(response.status).to eq(401) }
          it { expect(result['error']['message']).to eq 'invalid auth_token' }
        end
      end
    end

    describe 'invalid params' do
      before { post 'login' }
      it { expect(result).to eq("error"=>{"code"=>"PARAMETER_MISSING", "message"=>"param is missing or the value is empty: user"}) }
      it { expect(response.status).to eq 400 }
    end

    describe 'community support' do
      let(:user) { create :public_user, community: 'pfp', sms_code: "123456" }
      before { post 'login', user: {phone: user.phone, sms_code: "123456"} }

      context "when using the user's community" do
        with_community 'pfp'
        it { expect(response.status).to eq(200) }
      end

      context "when using a different community than the user's" do
        with_community 'entourage'
        it { expect(response.status).to eq(401) }
        it { expect(result).to eq({"error"=>{"code"=>"UNAUTHORIZED", "message" => "wrong phone / sms_code"}}) }
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
                                                             "roles"=>[],
                                                             "about" => nil,
                                                             "user_type"=>"pro",
                                                             "token"=>user.token,
                                                             "has_password"=>false,
                                                             "address"=>nil,
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
                                                             "partner"=>nil,
                                                             "memberships"=>[],
                                                             "conversation"=>{"uuid"=>"1_list_#{user.id}"}
                                                           }}) }
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
      subject { patch 'update', token: user.token, user: { email:'new@e.mail' } }
      let(:deliveries_campaigns) { ActionMailer::Base.deliveries.map { |e| e['X-Mailjet-Campaign'].value } }

      context "user has no email" do
        let!(:user) { create :public_user, email: nil, first_sign_in_at: 30.seconds.ago }
        let(:time) { Time.zone.now.change(sec: 0) }
        before { Timecop.freeze(time) }
        before { subject }
        it { expect(deliveries_campaigns).to eq ['welcome'] }
        it { expect(user.reload.onboarding_sequence_start_at).to eq time }
      end

      context "user has an email" do
        let!(:user) { create :public_user, email: "foo@bar.com", first_sign_in_at: 30.seconds.ago }
        before { subject }
        it { expect(deliveries_campaigns).to be_empty }
        it { expect(user.onboarding_sequence_start_at).to eq user.reload.onboarding_sequence_start_at }
      end

      context "user has no email but signed up more than a week ago" do
        let!(:user) { create :public_user, email: nil, first_sign_in_at: 10.days.ago }
        before { subject }
        it { expect(deliveries_campaigns).to be_empty }
      end

      context "user has no email but already started the onboarding sequence" do
        let(:onboarding_sequence_start_at) { 3.hours.ago.change(sec: 0) }
        let!(:user) { create :public_user, email: nil, first_sign_in_at: 30.seconds.ago, onboarding_sequence_start_at: onboarding_sequence_start_at }
        before { subject }
        it { expect(deliveries_campaigns).to be_empty }
        it { expect(user.reload.onboarding_sequence_start_at).to eq onboarding_sequence_start_at }
      end
    end

    describe "update sms_code" do
      before do
        @request.env['X-API-KEY'] = api_key
        patch 'update', token: user.token, user: { sms_code: '654321' }
      end

      context "on mobile" do
        let(:api_key) { 'api_debug' }
        it { expect(response.status).to eq 200 }
      end

      context "on web" do
        let(:api_key) { 'api_debug_web' }
        it { expect(response.status).to eq 400 }
      end
    end

    describe "update password" do
      before { patch 'update', token: user.token, user: params }
      let(:error_message) { JSON.parse(response.body)['error']['message'] }

      context "valid parameters" do
        let(:params) { {password: "new password"} }
        it { expect(response.status).to eq 200 }
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

    describe "reset password" do
      before do
        user.update!(password: "P@ssw0rd")
        @request.env['X-API-KEY'] = api_key
        patch 'code', {id: "me", user: { phone: user.phone }, code: {action: "regenerate"}, format: :json}
      end

      context "from web" do
        let(:api_key) { 'api_debug_web' }
        it { expect(user.reload.encrypted_password).to be_nil }
      end

      context "from mobile" do
        let(:api_key) { 'api_debug' }
        it { expect(user.reload.encrypted_password).to be_present }
      end
    end

    describe "missing phone" do
      before { patch 'code', {id: "me", user: { foo: "bar" }, code: {action: "regenerate"}, format: :json} }
      it { expect(response.status).to eq(400) }
    end

    describe "unknown phone" do
      before { patch 'code', {id: "me", user: { phone: "0000" }, code: {action: "regenerate"}, format: :json} }
      it { expect(response.status).to eq(404) }
      it { expect(JSON.parse(response.body)['error']['code']).to eq 'USER_NOT_FOUND' }
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
      it { expect(User.last.roles).to eq([]) }
      it { expect(User.last.phone).to eq("+33612345678") }
      it { expect(JSON.parse(response.body)["user"]["id"]).to eq(User.last.id) }

      context "community support" do
        with_community :pfp
        it { expect(User.last.community).to eq("pfp") }
        it { expect(User.last.roles).to eq([:not_validated]) }
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
    let(:partner) { create :partner }
    let!(:user) { create :pro_user, partner: partner }

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
                                                           "roles"=>[],
                                                           "about"=>nil,
                                                           "token"=>user.token,
                                                           "user_type"=>"pro",
                                                           "avatar_url"=>nil,
                                                           "has_password"=>false,
                                                           "address"=>nil,
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
                                                              "small_logo_url"=>"https://s3-eu-west-1.amazonaws.com/entourage-ressources/check-small.png",
                                                              "description"=>"MyDescription",
                                                              "phone"=>nil,
                                                              "address"=>nil,
                                                              "website_url"=>nil,
                                                              "email"=>nil,
                                                              "default"=>true},
                                                           "memberships"=>[],
                                                           "conversation"=>{"uuid"=>"1_list_#{user.id}"}
                                                         }}) }

        context "when you have an address" do
          let(:address) { create :address }
          let(:user) { create :public_user, address: address }
          it {
            expect(JSON.parse(response.body)['user']['address']).to eq(
              "latitude" => 1.5,
              "longitude" => 1.5,
              "display_address" => "rue Pizza, 75020",
            )
          }
        end
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
                                                           "roles"=>[],
                                                           "about"=>nil,
                                                           "token"=>user.token,
                                                           "user_type"=>"pro",
                                                           "avatar_url"=>nil,
                                                           "has_password"=>false,
                                                           "address"=>nil,
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
                                                              "small_logo_url"=>"https://s3-eu-west-1.amazonaws.com/entourage-ressources/check-small.png",
                                                              "description"=>"MyDescription",
                                                              "phone"=>nil,
                                                              "address"=>nil,
                                                              "website_url"=>nil,
                                                              "email"=>nil,
                                                              "default"=>true},
                                                           "memberships"=>[],
                                                           "conversation"=>{"uuid"=>"1_list_#{user.id}"}
                                                         }}) }
      end

      context "get someone else profile" do
        let(:other_user) { FactoryGirl.create(:pro_user, about: "about") }
        let!(:conversation) { nil }
        before { get :show, id: other_user.id, token: user.token }
        it { expect(response.status).to eq(200) }
        it { expect(JSON.parse(response.body)).to eq({"user"=>
                                                          {"id"=>other_user.id,
                                                           "display_name"=>"John D",
                                                           "first_name"=>"John",
                                                           "last_name"=>"D",
                                                           "roles"=>[],
                                                           "about"=>"about",
                                                           "avatar_url"=>nil,
                                                           "user_type"=>"pro",
                                                           "organization"=>{"name"=>other_user.organization.name, "description"=>"Association description", "phone"=>other_user.organization.phone, "address"=>other_user.organization.address, "logo_url"=>nil},
                                                           "stats"=>{
                                                               "tour_count"=>0,
                                                               "encounter_count"=>0,
                                                               "entourage_count"=>0,
                                                           },
                                                           "partner"=>nil,
                                                           "memberships"=>[],
                                                           "conversation"=>{"uuid"=>"1_list_#{user.id}-#{other_user.id}"}
                                                         }}) }

        context "when the two users have an existing conversation" do
          let!(:conversation) { create :conversation, participants: [user, other_user] }
          it { expect(result['user']['conversation']['uuid']).to eq conversation.uuid_v2 }
        end

        context "when conversations are disabled" do
          let!(:conversation) {
            expect(ConversationService)
              .to receive(:conversations_allowed?).with(from: user, to: other_user)
              .and_return(false)
          }
          it { expect(result['user']).not_to have_key 'conversation' }
        end
      end

      context "roles" do
        with_community :pfp
        let(:other_user) { FactoryGirl.create(:public_user, roles: [:visitor, :coordinator]) }
        let!(:join_request)  { create :join_request, user: other_user, joinable_factory: :private_circle, status: :accepted }
        let!(:join_request2) { create :join_request, user: other_user, joinable_factory: :private_circle, status: :pending }
        before { get :show, id: other_user.id, token: user.token }
        it { expect(JSON.parse(response.body)['user']['roles']).to eq ['coordinator', 'visitor'] }
        it { expect(JSON.parse(response.body)['user']['memberships']).to eq [{"type"=>"private_circle", "list"=>[{"id"=>join_request.joinable_id, "title"=>"Les amis d'Henriette", "number_of_people"=>1}]}, {"type"=>"neighborhood", "list"=>[]}] }
      end
    end
  end

  describe "DELETE destroy" do
    before { Timecop.freeze(Time.parse("10/10/2010").at_beginning_of_day) }
    before { MailchimpService.stub(:strong_unsubscribe) }
    let!(:user) { FactoryGirl.create(:pro_user, deleted: false, phone: "0612345678", email: "foo@bar.com") }
    before { delete :destroy, id: user.to_param, token: user.token }
    it { expect(user.reload.deleted).to be true }
    it { expect(user.reload.phone).to eq("+33612345678-2010-10-10 00:00:00") }
    it { expect(user.reload.email).to eq("foo@bar.com-2010-10-10 00:00:00") }
    it { expect(response.status).to eq(200) }
    it do
      expect(MailchimpService)
      .to have_received(:strong_unsubscribe)
      .with(
        list: :newsletter,
        email: user.email,
        reason: "compte supprimé dans l'app"
      )
    end
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

  describe 'POST #address' do
    let(:user) { create :public_user }
    subject { post 'address', address: address, id: user.id, token: user.token }
    context "valid params" do
      let(:address) { { place_name: "75012", latitude: 48.835085, longitude: 2.382165 } }
      before { subject }
      it { expect(response.status).to eq 200 }
      it { expect(JSON.parse(response.body)).to eq(
        "address"=>{
          "display_address"=>"75012",
          "latitude"=>48.835085,
          "longitude"=>2.382165,
        })
      }
      it { expect(user.reload.address.attributes.symbolize_keys).to include address }
    end

    context "invalid params" do
      let(:address) { { place_name: nil, latitude: nil, longitude: nil } }
      before { subject }
      it { expect(response.status).to eq 400 }
      it { expect(JSON.parse(response.body)).to eq({
        "error"=>{
          "code"=>"CANNOT_UPDATE_ADDRESS",
          "message"=>[
            "Place name doit être rempli(e)",
            "Latitude doit être rempli(e)",
            "Longitude doit être rempli(e)"
          ]
        }
      }) }
      it { expect(user.reload.address_id).to be_nil }
      it { expect(Address.count).to eq 0 }
    end

    context "with a google place_id" do
      before do
        Geocoder.configure(api_key: 'something')
        stub_request(:get, /maps.googleapis.com/)
          .to_return(body: JSON.fast_generate(
            status: :OK,
            result: {
              name: 'My Place',
              geometry: {location: {lat: 1, lng: 2}},
              address_components: [
                {types: [:postal_code], long_name: '00001'},
                {types: [:country], short_name: 'FR'}
              ],
              place_id: 'new-place-id'
            }
          ))
      end

      context "when required attributes are missing" do
        let(:address) { { google_place_id: 'some-place-id' } }
        it do
          subject
          expect(Address.last&.attributes).to include(
            'place_name' => 'My Place',
            'latitude'  => 1.0,
            'longitude' => 2.0,
            'postal_code' => '00001',
            'country' => 'FR',
            'google_place_id' => 'new-place-id',
          )
        end
      end

      context "when required attributes are present" do
        let(:address) { { google_place_id: 'some-place-id', place_name: 'Some name', latitude: 4, longitude: 5 } }
        it "doesn't update the address with Google Places data at first"do
          Sidekiq::Testing.fake! { subject }
          expect(Address.last&.attributes).to include(
            'place_name' => 'Some name',
            'latitude'  => 4.0,
            'longitude' => 5.0,
            'postal_code' => nil,
            'country' => nil,
            'google_place_id' => 'some-place-id',
          )
        end
        it "updates the address queries with Google Places data asynchronously" do
          subject
          expect(Address.last&.attributes).to include(
            'place_name' => 'My Place',
            'latitude'  => 1.0,
            'longitude' => 2.0,
            'postal_code' => '00001',
            'country' => 'FR',
            'google_place_id' => 'new-place-id',
          )
        end
      end
    end
  end

  describe 'GET #email_preferences' do
    let(:category) { create :email_category }
    let(:other_category) { create :email_category }

    let(:user) { create :public_user}

    context "unsubscribe from a specific category" do
      subject { get :update_email_preferences, id: user.id, category: category.name, accepts_emails: false, signature: SignatureService.sign(user.id) }

      it do
        expect { subject }
        .to change { EmailPreferencesService.accepts_emails?(category: category.name, user: user) }
        .to(false)
      end

      it do
        subject
        expect(response.body).to match category.description
      end

      it do
        expect { subject }
        .not_to change { EmailPreferencesService.accepts_emails?(category: other_category.name, user: user) }
        .from(true)
      end
    end

    context "unsubscribe from all emails" do
      subject { get :update_email_preferences, id: user.id, category: :all, accepts_emails: false, signature: SignatureService.sign(user.id) }

      it do
        expect { subject }
        .to change { EmailPreferencesService.accepts_emails?(category: category.name, user: user) }
        .to(false)
      end

      it do
        expect { subject }
        .to change { EmailPreferencesService.accepts_emails?(category: other_category.name, user: user) }
        .to(false)
      end
    end
  end
end
