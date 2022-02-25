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
        before { post 'login', params: { user: {phone: user.phone, sms_code: "123456"}, format: 'json' } }
        it { expect(response.status).to eq(200) }

        it "renders user" do
          expect(result).to eq({
            "user" => {
              "id" => user.id,
              "uuid" => user.id.to_s,
              "email" => user.email,
              "display_name" => "John D.",
              "first_name" => "John",
              "last_name" => "Doe",
              "roles" => [],
              "about" => nil,
              "token" => user.token,
              "user_type" => "pro",
              "has_password" => false,
              "address" => nil,
              "address_2" => nil,
              "avatar_url" => "https://foobar.s3-eu-west-1.amazonaws.com/300x300/avatar.jpg",
              "organization" => {
                "name" => user.organization.name,
                "description" => "Association description",
                "phone" => user.organization.phone,
                "address" => user.organization.address,
                "logo_url" => nil
              },
              "stats" => {
                "tour_count" => 0,
                "encounter_count" => 0,
                "entourage_count" => 0,
                "actions_count" => 0,
                "ask_for_help_creation_count" => 0,
                "contribution_creation_count" => 0,
                "events_count" => 0,
                "good_waves_participation" => false,
              },
              "partner" => {
                "id" => partner.id,
                "name" => "MyString",
                "large_logo_url" => "MyString",
                "small_logo_url" => "https://s3-eu-west-1.amazonaws.com/entourage-ressources/check-small.png",
                "description" => "MyDescription",
                "donations_needs" => nil,
                "volunteers_needs" => nil,
                "phone" => nil,
                "address"  =>  "174 rue Championnet, Paris",
                "website_url" => nil,
                "email" => nil,
                "default" => true,
                "user_role_title" => nil
              },
              "memberships" => [],
              "conversation" => {
                "uuid" => "1_list_#{user.id}"
              },
              "firebase_properties" => {
                "ActionZoneDep" => "not_set",
                "ActionZoneCP" => "not_set",
                "Goal" => "no_set",
                "Interests" => "none"
              },
              "anonymous" => false,
              "feature_flags" => {
                "organization_admin" => false
              },
              "engaged" => false,
              "goal" => nil,
              "phone" => user.phone,
              "unread_count" => 0,
              "interests" => [],
              "travel_distance" => 10,
              "permissions" => {
                "outing" => { "creation" => true }
              },
            },
            "first_sign_in" => true
          })
        end
      end

      describe "first_sign_in_at" do
        subject { post 'login', params: { user: {phone: user.phone, sms_code: "123456"} } }

        context "on the first login" do
          let(:time) { Time.zone.now.change(sec: 0) }
          before { Timecop.freeze(time) }
          before { subject }
          it { expect(user.reload.first_sign_in_at).to eq time }
          it { expect(result['first_sign_in']).to be true }
        end

        context "on subsequent logins" do
          let(:time) { 1.week.ago.change(sec: 0) }
          before { user.update_column(:first_sign_in_at, time) }
          before { subject }
          it { expect(user.reload.first_sign_in_at).to eq time }
          it { expect(result['first_sign_in']).to be false }
        end
      end

      context 'invalid sms code' do
        before { post 'login', params: { user: {phone: user.phone, sms_code: "invalid code"}, format: 'json' } }
        it { expect(response.status).to eq(401) }
        it { expect(result).to eq({"error"=>{"code"=>"UNAUTHORIZED", "message" => "wrong phone / sms_code"}}) }
      end

      describe "sms_code / password logic" do
        def login params
          post 'login', params: { user: {phone: user.phone}.merge(params) }
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
        before { post 'login', params: { user: {phone: "1234x"}, format: 'json' } }
        it { expect(response.status).to eq(401) }
        it { expect(result).to eq({"error"=>{"code"=>"INVALID_PHONE_FORMAT", "message"=>"invalid phone number format"}}) }
      end

      context 'phone format handling' do
        let!(:user) { create :public_user, phone: "+33600000001", sms_code: "123456" }
        before { post 'login', params: { user: {phone: "+33 (0) 6 00 00 00 01 ", sms_code: "123456"}, format: 'json' } }
        it { expect(response.status).to eq(200) }
      end

      context 'auth_token' do
        let(:token_expiration) { 24.hours.from_now }
        let(:token_user_id) { user.id }
        let(:token_payload) { "#{token_user_id}-#{token_expiration.to_i}" }
        let(:token_signature) { SignatureService.sign(token_payload, salt: user.token) }
        let(:token) { "1_#{token_payload}-#{token_signature}" }

        before { post 'login', params: { user: {auth_token: token} } }

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
      before { post 'login', params: { user: {phone: user.phone, sms_code: "123456"} } }

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
        before { post 'login', params: { user: {email: 'not_existing@nowhere.com', sms_code: 'sms code'}, format: 'json' } }
        it { expect(response.status).to eq(401) }
      end
      context 'using the phone number and sms code' do
        before { post 'login', params: { user: {phone: 'phone', sms_code: 'sms code'}, format: 'json' } }
        it { expect(response.status).to eq(401) }
      end
    end
    context 'when user is deleted' do
      let(:deleted_user) { FactoryBot.create(:pro_user, deleted: true, sms_code: "123456") }
      before { post 'login', params: { user: {phone: deleted_user.phone, sms_code: "123456"}, format: 'json' } }
      it { expect(response.status).to eq(401) }
      it { expect(result).to eq({"error"=>{"code"=>"DELETED", "message"=>"user is deleted"}}) }
    end
    context 'when user is not deleted' do
      let(:not_deleted_user) { FactoryBot.create(:pro_user, deleted: false, sms_code: "123456") }
      before { post 'login', params: { user: {phone: not_deleted_user.phone, sms_code: "123456"}, format: 'json' } }
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

      before { post 'login', params: { user: {phone: user.phone, sms_code: "123456"}, format: 'json' } }
      it { expect(JSON.parse(response.body)).to eq({
        "user" => {
          "id" => user.id,
          "uuid" => user.id.to_s,
          "email" => user.email,
          "display_name" => "John D.",
          "first_name" => "John",
          "last_name" => "Doe",
          "roles" => [],
          "about" => nil,
          "user_type" => "pro",
          "token" => user.token,
          "has_password" => false,
          "address" => nil,
          "address_2" => nil,
          "avatar_url" => "https://foobar.s3-eu-west-1.amazonaws.com/300x300/avatar.jpg",
          "organization" => {
            "name" => user.organization.name,
            "description" => "Association description",
            "phone" => user.organization.phone,
            "address" => user.organization.address,
            "logo_url" => nil
          },
          "stats" => {
            "tour_count" => 2,
            "encounter_count" => 3,
            "entourage_count" => 1,
            "actions_count" => 0,
            "ask_for_help_creation_count" => 1,
            "contribution_creation_count" => 0,
            "events_count" => 0,
            "good_waves_participation" => false,
          },
          "partner" => nil,
          "memberships" => [],
          "conversation" => {
            "uuid" => "1_list_#{user.id}"
          },
          "firebase_properties" => {
            "ActionZoneDep" => "not_set",
            "ActionZoneCP" => "not_set",
            "Goal" => "no_set",
            "Interests" => "none"
          },
          "anonymous" => false,
          "feature_flags" => {
            "organization_admin" => false
          },
          "engaged" => true,
          "goal" => nil,
          "phone" => user.phone,
          "unread_count" => 0,
          "interests" => [],
          "travel_distance" => 10,
          "permissions" => {
            "outing" => { "creation" => false }
          },
        },
        "first_sign_in" => true
      })}
    end

    context "blocked user" do
      let!(:user) { create :pro_user, sms_code: "123456", validation_status: "blocked", avatar_key: nil }
      before { post 'login', params: { user: {phone: user.phone, sms_code: "123456"}, format: 'json' } }
      it { expect(response.status).to eq(401) }
      it { expect(result).to eq({"error"=>{"code"=>"DELETED", "message"=>"user is deleted"}}) }
    end

    context "no avatar" do
      let!(:user) { create :pro_user, sms_code: "123456", validation_status: "validated", avatar_key: nil }
      before { post 'login', params: { user: {phone: user.phone, sms_code: "123456"}, format: 'json' } }
      it { expect(JSON.parse(response.body)["user"]["avatar_url"]).to be_nil }
    end

    context "public user with version 1.2.0" do
      before { ApiRequest.any_instance.stub(:key_infos) { {version: "1.2.0", community: 'entourage'} } }
      let!(:user) { create :public_user, sms_code: "123456"}
      before { post 'login', params: { user: {phone: user.phone, sms_code: "123456"}, format: 'json' } }
      it { expect(response.status).to eq(200) }
    end

    context "apple formatted phone number" do
      let!(:user) { create :public_user, phone: "+40724593579", sms_code: "123456"}
      before { post 'login', params: { user: {phone: "+40 (724) 593 579", sms_code: "123456"}, format: 'json' } }
      it { expect(response.status).to eq(200) }
    end
  end

  describe 'PATCH update' do
    let!(:user) { create :pro_user, avatar_key: "avatar" }
    let!(:blocked_user) { create :pro_user, avatar_key: "avatar", email: 'blocked@email.com', validation_status: :blocked }

    context 'authentication is OK' do
      before { ENV["DISABLE_CRYPT"]="FALSE" }
      after { ENV["DISABLE_CRYPT"]="TRUE" }

      context 'params are valid' do
        before { patch 'update', params: { token:user.token, user: { email:'new@e.mail', sms_code:'654321', device_id: 'foo', device_type: 'android', avatar_key: 'foo.jpg', travel_distance: 12 }, format: :json } }
        it { expect(response.status).to eq(200) }
        it { expect(user.reload.email).to eq('new@e.mail') }
        it { expect(user.reload.avatar_key).to eq('foo.jpg') }
        it { expect(user.reload.travel_distance).to eq(12) }
        it { expect(BCrypt::Password.new(User.find(user.id).sms_code) == '654321').to be true }

        it "renders user" do
          expect(JSON.parse(response.body)["user"]["id"]).to eq(user.id)
        end
      end

      context 'strips first_name, last_name and email' do
        before { patch 'update', params: { token:user.token, user: { first_name: 'Claude ', last_name: 'Shannon ', email:'cs@bell.com '} } }
        it { expect(user.reload.first_name).to eq('Claude') }
        it { expect(user.reload.last_name).to eq('Shannon') }
        it { expect(user.reload.email).to eq('cs@bell.com') }
      end

      context 'try to update phone number: no phone update is possible through API' do
        before { patch 'update', params: { token:user.token, user: { phone: '+33654876754' }, format: :json } }
        it { expect(response.status).to eq(200) }
        it { expect(user.reload.phone).not_to eq('+33654876754') }
      end

      context 'params are invalid' do
        before { patch 'update', params: { token:user.token, user: { email:'bademail', sms_code:'badcode' }, format: :json } }
        it { expect(response.status).to eq(400) }
        it { expect(result).to eq({"error"=>{"code"=>"CANNOT_UPDATE_USER", "message"=>["Email n'est pas valide"]}}) }
      end

      context 'about is too long' do
        before { patch 'update', params: { token:user.token, user: { about: "x" * 201 }, format: :json } }
        it { expect(response.status).to eq(400) }
        it { expect(result).to eq({"error"=>{"code"=>"CANNOT_UPDATE_USER", "message"=>["À propos est trop long (pas plus de 200 caractères)"]}}) }
      end

      context 'onboarding event tracking' do
        let(:request_timestamp) { 1.day.from_now.advance(seconds: rand(24.hours)) }

        before do
          Onboarding::UserEventsTracking.stub(:enable_tracking?) { true }
          user.save
        end

        subject do
          Timecop.freeze(request_timestamp) do
            patch 'update', params: { user: {first_name: 'Joe'}, token: user.token }
          end
        end

        def event
          Event.where(name: 'onboarding.profile.first_name.entered', user_id: user.id).first
        end

        context "user doesn't have a first_name" do
          let(:user) { build :public_user, first_name: nil }
          it do
            expect { subject }.to change { event.present? }.to(true)
          end
          it do
            subject
            expect(event.created_at).to be_within(1.second).of(request_timestamp)
          end
        end

        context "user already has a first_name" do
          let(:user) { build :public_user, first_name: 'Bill' }
          it do
            expect { subject }.not_to change { event.created_at }
          end
        end
      end

      context 'interest_list' do
        context 'good value' do
          before { patch 'update', params: { token: user.token, user: { interest_list: "sport, culture" } } }
          it { expect(result['user']).to include('interests' => ['culture', 'sport']) }
        end
      end

      context 'interests as a string' do
        context 'good value' do
          before { patch 'update', params: { token: user.token, user: { interests: "sport, culture" } } }
          it { expect(result['user']).to include('interests' => ['culture', 'sport']) }
        end
      end

      context 'interests as an array' do
        context 'good value but other_interest is missing' do
          before { patch 'update', params: { token: user.token, user: { interests: ["sport", "culture", "other"] } } }
          it { expect(response.status).to eq(400) }
        end
      end

      context 'interests as an array' do
        context 'good value' do
          before { patch 'update', params: { token: user.token, user: { interests: ["sport", "culture", "other"], other_interest: 'foo' } } }
          it { expect(result['user']).to include('interests' => ['culture', 'sport', 'other']) }
        end
      end

      context 'interests as an array' do
        context 'wrong value' do
          before { patch 'update', params: { token: user.token, user: { interests: ["foo", "bar"] } } }
          it { expect(response.status).to eq(400) }
        end
      end

      context 'interests as a string' do
        context 'good value' do
          before { patch 'update', params: { token: user.token, user: { interests: "event_sdf, aide_sdf" } } }
          it { expect(result['user']).to include('interests' => ['aide_sdf', 'event_sdf']) }
        end
      end

      context 'interests as an array' do
        context 'good value' do
          before { patch 'update', params: { token: user.token, user: { interests: ["event_sdf", "aide_sdf"] } } }
          it { expect(result['user']).to include('interests' => ['aide_sdf', 'event_sdf']) }
        end
      end

      context 'updated email is valid' do
        before {
          expect_any_instance_of(SlackServices::SignalUserCreation).not_to receive(:notify)
          patch 'update', params: { token:user.token, user: { email:'new@e.mail' }, format: :json }
        }
        it { expect(response.status).to eq(200) }
      end

      context 'updated email is blocked' do
        before {
          expect_any_instance_of(SlackServices::SignalUserCreation).to receive(:notify)
          patch 'update', params: { token:user.token, user: { email:'blocked@email.com' }, format: :json }
        }
        it { expect(response.status).to eq(200) }
      end
    end

    context 'bad authentication' do
      before { patch 'update', params: { token:'badtoken', user: { email:'new@e.mail', sms_code:'654321' }, format: :json } }
      it { expect(response.status).to eq(401) }
    end

    describe "upload avatar" do
      let(:avatar) { fixture_file_upload('avatar.jpg', 'image/jpeg') }

      context "valid params" do
        it "sets user avatar key" do
          patch 'update', params: { token:user.token, user: { avatar: avatar }, format: :json }
          expect(user.reload.avatar_key).to eq("avatar")
        end
      end
    end

    describe "welcome email" do
      subject { patch 'update', params: { token: user.token, user: { email:'new@e.mail' } } }
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
        patch 'update', params: { token: user.token, user: { sms_code: '654321' } }
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
      before { patch 'update', params: { token: user.token, user: params } }
      let(:error_message) { JSON.parse(response.body)['error']['message'] }

      context "valid parameters" do
        let(:params) { {password: "new password"} }
        it { expect(response.status).to eq 200 }
      end
    end
  end

  describe 'PATCH code' do
    let!(:user) { create :pro_user, sms_code: "123456", avatar_key: "avatar" }

    describe "regenerate sms code" do
      before { patch 'code', params: { id: "me", user: { phone: user.phone }, code: {action: "regenerate"}, format: :json } }
      it { expect(response.status).to eq(200) }
      it { expect(user.reload.sms_code).to_not eq("123456") }
      it "renders user" do
        expect(JSON.parse(response.body)).to eq(
          "user" => {
            "phone" => user.phone
          }
        )
      end
    end

    describe "reset password" do
      before do
        user.update!(password: "P@ssw0rd")
        @request.env['X-API-KEY'] = api_key
        patch 'code', params: { id: "me", user: { phone: user.phone }, code: {action: "regenerate"}, format: :json }
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
      before { patch 'code', params: { id: "me", user: { foo: "bar" }, code: {action: "regenerate"}, format: :json } }
      it { expect(response.status).to eq(400) }
    end

    describe "unknown phone" do
      before { patch 'code', params: { id: "me", user: { phone: "0000" }, code: {action: "regenerate"}, format: :json } }
      it { expect(response.status).to eq(404) }
      it { expect(JSON.parse(response.body)['error']['code']).to eq 'USER_NOT_FOUND' }
    end

    describe "unknown action" do
      before { patch 'code', params: { id: "me", user: { phone: user.phone }, code: {action: "foo"}, format: :json } }
      it { expect(response.status).to eq(400) }
    end
  end

  describe 'POST request_phone_change' do
    let!(:user) { FactoryBot.create(:pro_user, phone: '+331234567890') }

    before { # stubs
      SlackServices::RequestPhoneChange.any_instance.stub(:webhook).with('url') { "https://www.google.fr" }
      SlackServices::RequestPhoneChange.any_instance.stub(:webhook).with('username') { SlackServices::RequestPhoneChange::USERNAME }
      SlackServices::RequestPhoneChange.any_instance.stub(:webhook).with('channel') { "#channel" }
      SlackServices::RequestPhoneChange.any_instance.stub(:link_to_user) { "https://www.google.fr" }
      stub_request(:post, "https://www.google.fr/").to_return(status: 200, body: "", headers: {})
    }

    before { # slack ping
      expect_any_instance_of(Slack::Notifier).to receive(:ping).with({
        attachments: [{ text: "https://www.google.fr"}, { text: "Téléphone requis : +330987654321"}, {text: "Département : "}],
        channel: "#channel",
        text: "<@clara> ou team modération (département : n/a) L'utilisateur John Doe, my@email.com a requis un changement de numéro de téléphone",
        username: SlackServices::RequestPhoneChange::USERNAME
      })
    }

    before { # user_phone_change history
      expect(UserPhoneChange).to receive(:create).with({
        user_id: user.id,
        kind: :request,
        phone_was: '+331234567890',
        phone: '+330987654321',
        email: 'my@email.com'
      })
    }

    it "request a phone change on Slack" do
      post 'request_phone_change', params: {
        user: { current_phone: '+331234567890', requested_phone: '+330987654321', email: 'my@email.com' },
        format: :json
      }
    end
  end

  describe "POST create" do
    it "creates a new user" do
      expect {
        post 'create', params: { user: {phone: "+33612345678"} }
      }.to change { User.count }.by(1)
    end

    context "valid params" do
      before { post 'create', params: { user: { phone: "+33612345678", travel_distance: 16 } } }
      it { expect(User.last.user_type).to eq("public") }
      it { expect(User.last.community).to eq("entourage") }
      it { expect(User.last.roles).to eq([]) }
      it { expect(User.last.phone).to eq("+33612345678") }
      it { expect(User.last.travel_distance).to eq(16) }
      it {
        expect(JSON.parse(response.body)).to eq(
          "user" => {
            "phone" => User.last.phone
          }
        )
      }

      context "community support" do
        with_community :pfp
        it { expect(User.last.community).to eq("pfp") }
        it { expect(User.last.roles).to eq([:not_validated]) }
      end
    end

    context "already has a user without email" do
      let!(:previous_user) { FactoryBot.create(:public_user, email: nil) }
      before { post 'create', params: { user: {phone: "+33612345678"} } }
      it { expect(response.status).to eq(201) }
    end

    context "user with Apple formated phone number" do
      before { post 'create', params: { user: {phone: "+40 (724) 593 579"} } }
      it { expect(User.last.phone).to eq("+40724593579") }
    end

    context "invalid params" do
      it "doesn't create a new user" do
        expect {
          post 'create', params: { user: {phone: "123"} }
        }.to change { User.count }.by(0)
      end

      it "returns error" do
        post 'create', params: { user: {phone: "123"} }
        user = User.last
        expect(response.status).to eq(400)
        expect(result).to eq({"error"=>{"code"=>"INVALID_PHONE_FORMAT", "message"=>"Phone devrait être au format +33... ou 06..."}})
      end
    end

    context "phone already exists" do
      let!(:existing_user) { FactoryBot.create(:public_user, phone: "+33612345678") }
      before { post 'create', params: { user: {phone: "+33612345678"} } }
      it { expect(User.count).to eq(1) }
      it { expect(response.status).to eq(400) }
      it { expect(result).to eq({"error"=>{"code"=>"PHONE_ALREADY_EXIST", "message"=>"Phone +33612345678 n'est pas disponible"}}) }
    end
  end

  describe 'GET show' do
    let(:partner) { create :partner }
    let!(:user) { create :pro_user, partner: partner }

    context "not signed in" do
      before { get :show, params: { id: user.id } }
      it { expect(response.status).to eq(401) }
    end

    context "user signed in" do
      context "get your own profile" do
        before { get :show, params: { id: user.id, token: user.token } }
        it { expect(response.status).to eq(200) }
        it { expect(JSON.parse(response.body)).to eq({
          "user" => {
            "id" => user.id,
            "uuid" => user.id.to_s,
            "email" => user.email,
            "display_name" => "John D.",
            "first_name" => "John",
            "last_name" => "Doe",
            "roles" => [],
            "about" => nil,
            "token" => user.token,
            "user_type" => "pro",
            "avatar_url" => nil,
            "has_password" => false,
            "address" => nil,
            "address_2" => nil,
            "organization" => {
              "name" => user.organization.name,
              "description" => "Association description",
              "phone" => user.organization.phone,
              "address" => user.organization.address,
              "logo_url" => nil
            },
            "stats" => {
               "tour_count" => 0,
               "encounter_count" => 0,
               "entourage_count" => 0,
               "actions_count" => 0,
               "ask_for_help_creation_count" => 0,
               "contribution_creation_count" => 0,
               "events_count" => 0,
               "good_waves_participation" => false,
            },
            "partner" => {
              "id" => partner.id,
              "name" => "MyString",
              "large_logo_url" => "MyString",
              "small_logo_url" => "https://s3-eu-west-1.amazonaws.com/entourage-ressources/check-small.png",
              "description" => "MyDescription",
              "donations_needs" => nil,
              "volunteers_needs" => nil,
              "phone" => nil,
              "address"  =>  "174 rue Championnet, Paris",
              "website_url" => nil,
              "email" => nil,
              "default" => true,
              "user_role_title" => nil},
            "memberships" => [],
            "conversation" => {
              "uuid" => "1_list_#{user.id}"
            },
            "firebase_properties" => {
             "ActionZoneDep" => "not_set",
             "ActionZoneCP" => "not_set",
             "Goal" => "no_set",
             "Interests" => "none"
            },
            "anonymous" => false,
            "feature_flags" => {
              "organization_admin" => false
            },
            "engaged" => false,
            "goal" => nil,
            "phone" => user.phone,
            "unread_count" => 0,
            "interests" => [],
            "travel_distance" => 10,
            "permissions" => {
              "outing" => { "creation" => true }
            },
          }
        }) }

        context "when you have an address" do
          let(:address) { create :address }
          let(:user) { create :public_user, addresses: [address] }
          it {
            expect(JSON.parse(response.body)['user']['address']).to eq(
              "latitude" => 1.5,
              "longitude" => 1.5,
              "display_address" => "rue Pizza, 75020",
              "position"=>1,
            )
          }
        end
      end

      context "get my profile with 'me' shortcut" do
        before { get :show, params: { id: "me", token: user.token } }
        it { expect(response.status).to eq(200) }
        it { expect(JSON.parse(response.body)).to eq({
          "user" => {
            "id" => user.id,
            "uuid" => user.id.to_s,
            "email" => user.email,
            "display_name" => "John D.",
            "first_name" => "John",
            "last_name" => "Doe",
            "roles" => [],
            "about" => nil,
            "token" => user.token,
            "user_type" => "pro",
            "avatar_url" => nil,
            "has_password" => false,
            "address" => nil,
            "address_2" => nil,
            "organization" => {
              "name" => user.organization.name,
              "description" => "Association description",
              "phone" => user.organization.phone,
              "address" => user.organization.address,
              "logo_url"=>nil
            },
            "stats" => {
               "tour_count" => 0,
               "encounter_count" => 0,
               "entourage_count" => 0,
               "actions_count" => 0,
               "ask_for_help_creation_count" => 0,
               "contribution_creation_count" => 0,
               "events_count" => 0,
               "good_waves_participation" => false,
            },
            "partner" => {
              "id" => partner.id,
              "name" => "MyString",
              "large_logo_url" => "MyString",
              "small_logo_url" => "https://s3-eu-west-1.amazonaws.com/entourage-ressources/check-small.png",
              "description" => "MyDescription",
              "donations_needs" => nil,
              "volunteers_needs" => nil,
              "phone" => nil,
              "address" => "174 rue Championnet, Paris",
              "website_url" => nil,
              "email" => nil,
              "default" => true,
              "user_role_title" => nil},
            "memberships" => [],
            "conversation" => {
              "uuid" => "1_list_#{user.id}"
            },
            "firebase_properties" => {
             "ActionZoneDep" => "not_set",
             "ActionZoneCP" => "not_set",
             "Goal" => "no_set",
             "Interests" => "none"
            },
            "anonymous" => false,
            "feature_flags" => {
              "organization_admin" => false
            },
            "engaged" => false,
            "goal" => nil,
            "phone" => user.phone,
            "unread_count" => 0,
            "interests" => [],
            "travel_distance" => 10,
            "permissions" => {
              "outing" => { "creation" => true }
            },
          }
        }) }
      end

      context "get my profile as an anonymous user" do
        let(:user) { AnonymousUserService.create_user($server_community) }
        before { get :show, params: { id: "me", token: user.token } }
        it { expect(result['user']['placeholders']).to eq ["firebase_properties", "address", "address_2"] }
      end

      context "get someone else profile" do
        let(:other_user) { FactoryBot.create(:pro_user, about: "about") }
        let!(:conversation) { nil }
        before { get :show, params: { id: other_user.id, token: user.token } }
        it { expect(response.status).to eq(200) }
        it { expect(JSON.parse(response.body)).to eq({
          "user" => {
            "id" => other_user.id,
            "display_name" => "John D.",
            "first_name" => "John",
            "last_name" => "D",
            "roles" => [],
            "about" => "about",
            "avatar_url" => nil,
            "user_type" => "pro",
            "organization" => {
              "name" => other_user.organization.name,
              "description" => "Association description",
              "phone" => other_user.organization.phone,
              "address" => other_user.organization.address,
              "logo_url" => nil
            },
            "stats" => {
              "tour_count" => 0,
              "encounter_count" => 0,
              "entourage_count" => 0,
              "actions_count" => 0,
              "ask_for_help_creation_count" => 0,
              "contribution_creation_count" => 0,
              "events_count" => 0,
              "good_waves_participation" => false,
            },
            "engaged" => false,
            "unread_count" => 0,
            "partner" => nil,
            "permissions" => {
              "outing" => { "creation" => false }
            },
            "memberships" => [],
            "conversation" => {
              "uuid" => "1_list_#{user.id}-#{other_user.id}"
            }
          }
        }) }

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
        let(:other_user) { FactoryBot.create(:public_user, roles: [:ambassador]) }
        let!(:join_request)  { create :join_request, user: other_user, status: :accepted }
        let!(:join_request2) { create :join_request, user: other_user, status: :pending }
        before { get :show, params: { id: other_user.id, token: user.token } }
        it { expect(JSON.parse(response.body)['user']['roles']).to eq ['ambassador'] }
        it { expect(JSON.parse(response.body)['user']['memberships']).to eq [] }
      end

      context "firebase_properties" do
        context "action zone" do
          let(:user) { create :public_user, addresses: [address].compact }
          before { get :show, params: { id: user.id, token: user.token } }
          let(:firebase_properties) { result['user']['firebase_properties'] }

          context "no action zone" do
            let(:address) { nil }
            it { expect(firebase_properties).to include(
              'ActionZoneDep' => 'not_set',
              'ActionZoneCP'  => 'not_set'
            ) }
          end

          context "outside of FR" do
            let(:address) { create :address, country: :BE }
            it { expect(firebase_properties).to include(
              'ActionZoneDep' => 'not_FR',
              'ActionZoneCP'  => 'not_FR'
            ) }
          end

          context "only department" do
            let(:address) { create :address, country: :FR, postal_code: '69XXX' }
            it { expect(firebase_properties).to include(
              'ActionZoneDep' => '69',
              'ActionZoneCP'  => 'not_set'
            ) }
          end

          context "full postal code" do
            let(:address) { create :address, country: :FR, postal_code: '75012' }
            it { expect(firebase_properties).to include(
              'ActionZoneDep' => '75',
              'ActionZoneCP'  => '75012'
            ) }
          end
        end
      end
    end
  end

  describe "DELETE destroy" do
    before { Timecop.freeze(Time.parse("10/10/2010").at_beginning_of_day) }
    before { MailchimpService.stub(:strong_unsubscribe) }
    let!(:user) { FactoryBot.create(:pro_user, deleted: false, phone: "0612345678", email: "foo@bar.com") }
    before { delete :destroy, params: { id: user.to_param, token: user.token } }
    it { expect(user.reload.deleted).to be true }
    it { expect(user.reload.phone).to eq("+33612345678-2010-10-10 00:00:00") }
    it { expect(user.reload.email).to eq("foo@bar.com-2010-10-10 00:00:00") }
    it { expect(response.status).to eq(200) }
    it do
      expect(MailchimpService).to have_received(:strong_unsubscribe).with(
        list: :newsletter,
        email: user.email,
        reason: "compte supprimé dans l'app"
      )
    end
    it { expect(JSON.parse(response.body)).to have_key('user') }
  end

  describe 'POST #report' do
    let(:reporting_user) { create :public_user }
    let(:reported_user)  { create :public_user }
    let(:result) { JSON.parse(response.body) }

    ENV['SLACK_SIGNAL_USER_WEBHOOK'] = '{"url":"https://url.to.slack.com","channel":"channel","username":"signal-user-creation"}'

    before { stub_request(:post, "https://url.to.slack.com").to_return(status: 200) }

    context "valid params" do
      before {
        expect_any_instance_of(SlackServices::SignalUser).to receive(:notify)
        post 'report', params: { token: reporting_user.token, id: reported_user.id, user_report: { message: 'message' } }
      }

      it { expect(response.status).to eq 201 }
    end

    context "valid params with signals but no message" do
      before {
        expect_any_instance_of(SlackServices::SignalUser).to receive(:notify)
        post 'report', params: { token: reporting_user.token, id: reported_user.id, user_report: { message: nil, signals: ['spam'] } }
      }

      it { expect(response.status).to eq 201 }
    end

    context "invalid signal" do
      before {
        expect_any_instance_of(SlackServices::SignalUser).not_to receive(:notify)
        post 'report', params: { token: reporting_user.token, id: reported_user.id, user_report: { message: nil, signals: ['foo'] } }
      }

      it { expect(response.status).to eq 400 }
      it { expect(result['message']).to eq "Signal is invalid" }
    end

    context "missing message without signals" do
      before {
        expect_any_instance_of(SlackServices::SignalUser).not_to receive(:notify)
        post 'report', params: { token: reporting_user.token, id: reported_user.id, user_report: { message: '' } }
      }

      it { expect(response.status).to eq 400 }
      it { expect(result['message']).to eq "Message is required" }
    end

    context "empty signals" do
      before {
        expect_any_instance_of(SlackServices::SignalUser).not_to receive(:notify)
        post 'report', params: { token: reporting_user.token, id: reported_user.id, user_report: { message: 'foobar', signals: [''] } }
      }

      it { expect(response.status).to eq 400 }
      it { expect(result['message']).to eq "Signal is invalid" }
    end
  end

  describe 'POST #presigned_avatar_upload' do
    let(:user) { create :public_user }

    before { post :presigned_avatar_upload, params: { id: UserService.external_uuid(user), token: user.token, content_type: 'image/jpeg' } }
    it { expect(response.status).to eq(200) }
    it { expect(JSON.parse(response.body)).to have_key('avatar_key') }
    it { expect(JSON.parse(response.body)).to have_key('presigned_url') }
  end

  describe 'POST #address' do
    let(:user) { create :public_user }
    subject { post 'address', params: { address: address, id: UserService.external_uuid(user), token: user.token } }
    context "valid params" do
      let(:address) { { place_name: "75012", latitude: 48.835085, longitude: 2.382165 } }
      before { subject }
      it { expect(response.status).to eq 200 }
      it { expect(JSON.parse(response.body)).to eq(
        "address"=>{
          "display_address"=>"75012",
          "latitude"=>48.835085,
          "longitude"=>2.382165,
          "position"=>1,
        },
        "firebase_properties"=>{
          "ActionZoneDep"=>"not_set",
          "ActionZoneCP"=>"not_set",
          "Goal" => "no_set",
          "Interests" => "none",
        })
      }
      it { expect(user.reload.address.attributes.symbolize_keys).to include address }
    end

    context "invalid params" do
      let(:address) { { place_name: nil, latitude: nil, longitude: nil } }
      before { subject }

      shared_examples "common tests" do
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
        it { expect(Address.count).to eq 0 }
      end

      context "with a standard user" do
        include_examples "common tests"
        it { expect(user.reload.address_id).to be_nil }
      end

      context "with an anonymous user" do
        let(:user) { AnonymousUserService.create_user($server_community) }
        include_examples "common tests"
      end
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

        context "with a standard user" do
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

        context "with an anonymous user" do
          let(:user) { AnonymousUserService.create_user($server_community) }
          it do
            subject
            expect(result).to eq(
              "address"=>{
                "display_address"=>"My Place, 00001",
                "latitude"=>1.0,
                "longitude"=>2.0,
                "position"=>1,
              },
              "firebase_properties"=>{
                "ActionZoneDep"=>"00",
                "ActionZoneCP"=>"00001",
                "Goal" => "no_set",
                "Interests" => "none"
              }
            )
          end
          it { expect { subject }.not_to change { Address.count } }
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

  describe 'POST following' do
    let(:user) { create :public_user }
    let(:partner) { create :partner }

    subject { post 'following', params: { following: following, id: 'me', token: user.token } }

    context "create" do
      let(:following) { { partner_id: partner.id, active: true } }
      before { subject }
      it { expect(response.status).to eq 200 }
      it { expect(JSON.parse(response.body)).to eq(
        "following" => {
          "partner_id" => partner.id,
          "active" => true
        }
      )}
      it { expect(Following.where(user: user, partner: partner).pluck(:active)).to eq [true] }
    end

    context "unfollow" do
      let!(:existing) { create :following, user: user, partner: partner }
      let(:following) { { partner_id: partner.id, active: false } }
      before { subject }
      it { expect(response.status).to eq 200 }
      it { expect(JSON.parse(response.body)).to eq(
        "following" => {
          "partner_id" => partner.id,
          "active" => false
        }
      )}
      it { expect(Following.where(user: user, partner: partner).pluck(:active)).to eq [false] }
    end
  end

  describe 'POST lookup' do
    let(:user) { create :public_user }
    before { post 'lookup', params: { token: user.token, phone: user.phone } }
    it { expect(response.status).to eq(200) }
    it { expect(JSON.parse(response.body)).to have_key('status')}
  end

  describe 'GET #update_email_preferences' do
    let(:category) { create :email_category }
    let(:other_category) { create :email_category }

    let(:user) { create :public_user}

    context "unsubscribe from a specific category" do
      subject { get :update_email_preferences, params: { id: user.id, category: category.name, accepts_emails: false, signature: SignatureService.sign(user.id) } }

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
      subject { get :update_email_preferences, params: { id: user.id, category: :all, accepts_emails: false, signature: SignatureService.sign(user.id) } }

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

  describe 'GET confirm_address_suggestion' do
    let(:user) { create :public_user }
    let!(:address) { create :address, country: :FR, postal_code: '75018', user_id: user.id }

    before { get :confirm_address_suggestion, params: { id: user.id } }
    it { expect(response.status).to eq(200) }
  end

  describe 'POST confirm_address_suggestion' do
    pending "add some examples to (or delete) #{__FILE__}"
  end

  describe 'POST ethics_charter_signed' do
    let(:user) { create :public_user }

    before { post :ethics_charter_signed, params: { form_response: nil } }
    it { expect(response.status).to eq(200) }

    context 'further tests' do
      pending "add some examples to (or delete) #{__FILE__}"
    end
  end

  describe 'GET organization_admin_redirect' do
    let(:user) { create :partner_user }

    before {
      UserServices::UserAuthenticator.stub(:auth_token) { 'foo' }
      get :organization_admin_redirect, params: { message: 'webapp_logout', token: user.token }
    }
    it { expect(response.status).to eq(302) }
    it { should redirect_to organization_admin_auth_url(auth_token: 'foo', message: 'webapp_logout') }
  end
end
