require 'rails_helper'
include AuthHelper
include CommunityHelper

RSpec.describe Api::V1::UsersController, type: :controller do
  render_views

  let(:result) { JSON.parse(response.body) }

  describe 'POST #login' do
    before { ENV['DISABLE_CRYPT']='FALSE' }
    after { ENV['DISABLE_CRYPT']='TRUE' }

    context 'when the user exists' do
      let(:partner) { create :partner }
      let!(:user) { create :pro_user, sms_code: '123456', avatar_key: 'avatar', partner: partner }

      context 'when the phone number and sms code are valid' do
        before { post 'login', params: { user: {phone: user.phone, sms_code: '123456'}, format: 'json' } }
        it { expect(response.status).to eq(200) }

        it 'renders user' do
          expect(result).to eq({
            'user' => {
              'id' => user.id,
              'uuid' => user.id.to_s,
              'email' => user.email,
              'lang' => user.lang,
              'availability' => user.availability,
              'display_name' => 'John D.',
              'first_name' => 'John',
              'last_name' => 'Doe',
              'roles' => ['Association'],
              'about' => nil,
              'token' => user.token,
              'user_type' => 'pro',
              'has_password' => false,
              'address' => nil,
              'address_2' => nil,
              'avatar_url' => 'https://foobar.s3-eu-west-1.amazonaws.com/300x300/avatar.jpg',
              'stats' => {
                'tour_count' => 0,
                'encounter_count' => 0,
                'entourage_count' => 0,
                'actions_count' => 0,
                'ask_for_help_creation_count' => 0,
                'contribution_creation_count' => 0,
                'events_count' => 0,
                'outings_count' => 0,
                'neighborhoods_count' => 0,
                'good_waves_participation' => false,
              },
              'partner' => {
                'id' => partner.id,
                'name' => 'MyString',
                'image_url' => 'https://foobar.s3.eu-west-1.amazonaws.com/partners/logo/MyString',
                'description' => 'MyDescription',
                'donations_needs' => nil,
                'volunteers_needs' => nil,
                'phone' => nil,
                'address'  =>  '174 rue Championnet, Paris',
                'website_url' => nil,
                'email' => nil,
                'default' => true,
                'user_role_title' => nil
              },
              'memberships' => [],
              'conversation' => {
                'uuid' => "1_list_#{user.id}"
              },
              'firebase_properties' => {
                'ActionZoneDep' => 'not_set',
                'ActionZoneCP' => 'not_set',
                'Goal' => 'no_set',
                'Interests' => 'none'
              },
              'anonymous' => false,
              'feature_flags' => {
                'organization_admin' => false
              },
              'engaged' => false,
              'goal' => nil,
              'phone' => user.phone,
              'unread_count' => 0,
              'birthday' => false,
              'interests' => [],
              'involvements' => [],
              'orientations' => [],
              'gender' => nil,
              'concerns' => [],
              'travel_distance' => 40,
              'birthdate' => nil,
              'permissions' => {
                'outing' => { 'creation' => true }
              },
              'created_at' => user.created_at.iso8601(3),
            },
            'first_sign_in' => true
          })
        end
      end

      describe 'first_sign_in_at' do
        subject { post 'login', params: { user: {phone: user.phone, sms_code: '123456'} } }

        context 'on the first login' do
          let(:time) { Time.zone.now.change(sec: 0) }
          before { Timecop.freeze(time) }
          before { subject }
          it { expect(user.reload.first_sign_in_at).to eq time }
          it { expect(result['first_sign_in']).to be true }
        end

        context 'on subsequent logins' do
          let(:time) { 1.week.ago.change(sec: 0) }
          before { user.update_column(:first_sign_in_at, time) }
          before { subject }
          it { expect(user.reload.first_sign_in_at).to eq time }
          it { expect(result['first_sign_in']).to be false }
        end
      end

      context 'invalid sms code' do
        before { post 'login', params: { user: {phone: user.phone, sms_code: 'invalid code'}, format: 'json' } }
        it { expect(response.status).to eq(401) }
        it { expect(result).to eq({'error'=>{'code'=>'UNAUTHORIZED', 'message' => 'wrong phone / sms_code'}}) }
      end

      describe 'sms_code / password logic' do
        def login params
          post 'login', params: { user: {phone: user.phone}.merge(params) }
          OpenStruct.new(status: response.status, body: JSON.parse(response.body))
        end

        context "when the user doesn't have a password" do
          it { expect(login(sms_code: '123456').status).to eq 200 }
          it { expect(login(sms_code: '123456').body['user']['has_password']).to eq false }
        end

        context 'when the user has a password' do
          before { user.update(password: 'P@ssw0rd') }

          context 'on the web' do
            before { @request.env['X-API-KEY'] = 'api_debug_web' }
            it { expect(login(secret: 'P@ssw0rd').status).to eq 200 }
            it { expect(login(secret: 'P@ssw0rd').body['user']['has_password']).to eq true }
            it { expect(login(secret: '123456'  ).status).to eq 401 }
          end

          context 'on mobile' do
            it { expect(login(sms_code: 'P@ssw0rd').status).to eq 200 }
            it { expect(login(sms_code: 'P@ssw0rd').body['user']['has_password']).to eq true }
            it { expect(login(sms_code: '123456'  ).status).to eq 200 }
          end
        end
      end

      context 'invalid phone number format' do
        before { post 'login', params: { user: {phone: '1234x'}, format: 'json' } }
        it { expect(response.status).to eq(401) }
        it { expect(result).to eq({'error'=>{'code'=>'INVALID_PHONE_FORMAT', 'message'=>'invalid phone number format'}}) }
      end

      context 'phone format handling' do
        let!(:user) { create :public_user, phone: '+33600000001', sms_code: '123456' }
        before { post 'login', params: { user: {phone: '+33 (0) 6 00 00 00 01 ', sms_code: '123456'}, format: 'json' } }
        it { expect(response.status).to eq(200) }
      end

      context 'auth_token' do
        let(:token_expiration) { 24.hours.from_now }
        let(:token_user_id) { user.id }
        let(:token_payload) { "#{token_user_id}-#{token_expiration.to_i}" }
        let(:token_signature) { SignatureService.sign(token_payload, salt: user.token) }
        let(:token) { "1_#{token_payload}-#{token_signature}" }

        before { post 'login', params: { user: {auth_token: token} } }

        context 'valid token' do
          it { expect(response.status).to eq(200) }
          it { expect(result['user']['id']).to eq user.id }
        end

        context 'expired token' do
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
      it { expect(result).to have_key('error') }
      it { expect(result['error']['code']).to eq('PARAMETER_MISSING') }
      it { expect(result['error']['message']).to match('param is missing or the value is empty: user') }

      it { expect(response.status).to eq 400 }
    end

    describe 'community support' do
      let(:user) { create :public_user, community: 'pfp', sms_code: '123456' }
      before { post 'login', params: { user: {phone: user.phone, sms_code: '123456'} } }

      context "when using the user's community" do
        with_community 'pfp'
        it { expect(response.status).to eq(200) }
      end

      context "when using a different community than the user's" do
        with_community 'entourage'
        it { expect(response.status).to eq(401) }
        it { expect(result).to eq({'error'=>{'code'=>'UNAUTHORIZED', 'message' => 'wrong phone / sms_code'}}) }
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
      let(:deleted_user) { FactoryBot.create(:pro_user, deleted: true, sms_code: '123456') }
      before { post 'login', params: { user: {phone: deleted_user.phone, sms_code: '123456'}, format: 'json' } }
      it { expect(response.status).to eq(401) }
      it { expect(result).to eq({'error'=>{'code'=>'DELETED', 'message'=>'user is deleted'}}) }
    end
    context 'when user is not deleted' do
      let(:not_deleted_user) { FactoryBot.create(:pro_user, deleted: false, sms_code: '123456') }
      before { post 'login', params: { user: {phone: not_deleted_user.phone, sms_code: '123456'}, format: 'json' } }
      it { expect(response.status).to eq(200) }
    end

    context 'blocked user' do
      let!(:user) { create :pro_user, sms_code: '123456', validation_status: 'blocked', avatar_key: nil }
      before { post 'login', params: { user: {phone: user.phone, sms_code: '123456'}, format: 'json' } }
      it { expect(response.status).to eq(401) }
      it { expect(result).to eq({'error'=>{'code'=>'DELETED', 'message'=>'user is deleted'}}) }
    end

    context 'no avatar' do
      let!(:user) { create :pro_user, sms_code: '123456', validation_status: 'validated', avatar_key: nil }
      before { post 'login', params: { user: {phone: user.phone, sms_code: '123456'}, format: 'json' } }
      it { expect(JSON.parse(response.body)['user']['avatar_url']).to be_nil }
    end

    context 'public user with version 1.2.0' do
      before { ApiRequest.any_instance.stub(:key_infos) { {version: '1.2.0', community: 'entourage'} } }
      let!(:user) { create :public_user, sms_code: '123456'}
      before { post 'login', params: { user: {phone: user.phone, sms_code: '123456'}, format: 'json' } }
      it { expect(response.status).to eq(200) }
    end

    context 'apple formatted phone number' do
      let!(:user) { create :public_user, phone: '+33744219491', sms_code: '123456'}
      before { post 'login', params: { user: {phone: '+337 44 21 94 91', sms_code: '123456'}, format: 'json' } }
      it { expect(response.status).to eq(200) }
    end
  end

  describe 'PATCH update' do
    let!(:user) { create :pro_user, avatar_key: 'avatar' }
    let!(:blocked_user) { create :pro_user, avatar_key: 'avatar', email: 'blocked@email.com', validation_status: :blocked }

    context 'authentication is OK' do
      before { ENV['DISABLE_CRYPT']='FALSE' }
      after { ENV['DISABLE_CRYPT']='TRUE' }

      context 'params are valid' do
        before { patch 'update', params: { token: user.token, user: { lang: 'pl', email: 'new@e.mail', sms_code: '654321', device_id: 'foo', device_type: 'android', avatar_key: 'foo.jpg', travel_distance: 12, gender: 'secret', orientations: ['guide'] }, format: :json } }
        it { expect(response.status).to eq(200) }
        it { expect(user.reload.lang).to eq('pl') }
        it { expect(user.reload.email).to eq('new@e.mail') }
        it { expect(user.reload.avatar_key).to eq('foo.jpg') }
        it { expect(user.reload.travel_distance).to eq(12) }
        it { expect(user.reload.gender).to eq('secret') }
        it { expect(user.reload.orientation_list).to eq(['guide']) }
        it { expect(BCrypt::Password.new(User.find(user.id).sms_code) == '654321').to be true }

        it 'renders user' do
          expect(JSON.parse(response.body)['user']['id']).to eq(user.id)
        end
      end

      describe 'willing_to_engage_locally' do
        context 'true' do
          before { patch 'update', params: { token: user.token, user: { willing_to_engage_locally: true } } }
          it { expect(user.reload.willing_to_engage_locally).to eq(true) }
        end

        context 'true as string' do
          before { patch 'update', params: { token: user.token, user: { willing_to_engage_locally: 'true' } } }
          it { expect(user.reload.willing_to_engage_locally).to eq(true) }
        end

        context 'false' do
          before { patch 'update', params: { token: user.token, user: { willing_to_engage_locally: false } } }
          it { expect(user.reload.willing_to_engage_locally).to eq(false) }
        end
      end

      context 'strips first_name, last_name and email' do
        before { patch 'update', params: { token: user.token, user: { first_name: 'Claude ', last_name: 'Shannon ', email: 'cs@bell.com '} } }
        it { expect(user.reload.first_name).to eq('Claude') }
        it { expect(user.reload.last_name).to eq('Shannon') }
        it { expect(user.reload.email).to eq('cs@bell.com') }
      end

      context 'try to update phone number: no phone update is possible through API' do
        before { patch 'update', params: { token: user.token, user: { phone: '+33654876754' }, format: :json } }
        it { expect(response.status).to eq(200) }
        it { expect(user.reload.phone).not_to eq('+33654876754') }
      end

      context 'params are invalid' do
        before { patch 'update', params: { token: user.token, user: { email: 'bademail', sms_code: 'badcode' }, format: :json } }
        it { expect(response.status).to eq(400) }
        it { expect(result).to eq({'error'=>{'code'=>'CANNOT_UPDATE_USER', 'message'=>["Email n'est pas valide"]}}) }
      end

      context 'about is too long' do
        before { patch 'update', params: { token: user.token, user: { about: 'x' * 201 }, format: :json } }
        it { expect(response.status).to eq(400) }
        it { expect(result).to eq({'error'=>{'code'=>'CANNOT_UPDATE_USER', 'message'=>['À propos est trop long (pas plus de 200 caractères)']}}) }
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

        context 'user already has a first_name' do
          let(:user) { build :public_user, first_name: 'Bill' }
          it do
            expect { subject }.not_to change { event.created_at }
          end
        end
      end

      context 'not partner' do
        let!(:partner) { create :partner }

        before { patch 'update', params: { token: user.token, user: { partner_id: nil } } }

        it { expect(user.reload.association?).to eq(false) }
        it { expect(user.reload.partner_id).to eq(nil) }
      end

      context 'partner' do
        let!(:partner) { create :partner }

        before { patch 'update', params: { token: user.token, user: { partner_id: partner.id } } }

        it { expect(user.reload.association?).to eq(true) }
        it { expect(user.reload.partner_id).to eq(partner.id) }
      end

      context 'partner staff' do
        let!(:partner) { create :partner, staff: true }

        before { patch 'update', params: { token: user.token, user: { partner_id: partner.id } } }

        # partner staff should not be available from api
        it { expect(user.reload.association?).to eq(false) }
        it { expect(user.reload.partner_id).to eq(nil) }
      end

      context 'birthdate' do
        before { patch 'update', params: { token: user.token, user: { birthdate: '1970-12-30' } } }
        it { expect(user.reload.birthdate).to eq('1970-12-30') }
      end

      context 'gender' do
        before { patch 'update', params: { token: user.token, user: { gender: 'female' } } }
        it { expect(user.reload.gender).to eq('female') }
      end

      context 'discovery_source' do
        before { patch 'update', params: { token: user.token, user: { discovery_source: 'word_of_mouth' } } }
        it { expect(user.reload.discovery_source).to eq('word_of_mouth') }
      end

      # interest_list
      context 'interest_list' do
        context 'good value' do
          before { patch 'update', params: { token: user.token, user: { interest_list: 'sport, culture' } } }
          it { expect(result['user']).to include('interests' => match_array(['culture', 'sport'])) }
        end
      end

      context 'availability' do
        before { patch 'update', params: { token: user.token, user: { availability: { '2' => ['10:00-12:00'] } } } }

        it { expect(result['user']).to have_key('availability') }
        it { expect(result['user']).to include('availability' => { '2' => ['10:00-12:00'] }) }
      end

      context 'interests as a string' do
        context 'good value' do
          before { patch 'update', params: { token: user.token, user: { interests: 'sport, culture' } } }
          it { expect(result['user']).to include('interests' => match_array(['culture', 'sport'])) }
        end
      end

      context 'interests as an array' do
        context 'good value when other_interest is missing is also valid' do
          before { patch 'update', params: { token: user.token, user: { interests: ['sport', 'culture', 'other'] } } }
          it { expect(response.status).to eq(200) }
        end
      end

      context 'interests as an array' do
        context 'good value' do
          before { patch 'update', params: { token: user.token, user: { interests: ['sport', 'culture', 'other'], other_interest: 'foo' } } }
          it { expect(result['user']).to include('interests' => match_array(['culture', 'sport', 'other'])) }
        end
      end

      context 'interests as an array' do
        context 'good value' do
          before { patch 'update', params: { token: user.token, user: { interests: ['sport', 'culture', 'other'], other_interest: 'foo' } } }
          it { expect(result['user']).to include('interests' => match_array(['culture', 'sport', 'other'])) }
        end
      end

      context 'interests as an array' do
        context 'wrong value' do
          before { patch 'update', params: { token: user.token, user: { interests: ['foo', 'bar'] } } }
          it { expect(response.status).to eq(200) }
          it { expect(result['user']).to include('interests' => []) }
        end

        context 'wrong value as v7 interests' do
          before { patch 'update', params: { token: user.token, user: { interests: ['event_riverain', 'm_informer_riverain'] } } }
          it { expect(response.status).to eq(200) }
          it { expect(result['user']).to include('interests' => []) }
        end
      end

      # involvement_list
      context 'involvement_list' do
        context 'good value' do
          before { patch 'update', params: { token: user.token, user: { involvement_list: 'resources, outings' } } }
          it { expect(result['user']).to include('involvements' => match_array(['outings', 'resources'])) }
        end
      end

      context 'involvements as a string' do
        context 'good value' do
          before { patch 'update', params: { token: user.token, user: { involvements: 'resources, outings' } } }
          it { expect(result['user']).to include('involvements' => match_array(['outings', 'resources'])) }
        end
      end

      context 'involvements as an array' do
        context 'good value when other_involvement is missing is also valid' do
          before { patch 'update', params: { token: user.token, user: { involvements: ['resources', 'outings', 'both_actions'] } } }
          it { expect(response.status).to eq(200) }
        end
      end

      context 'involvements as an array' do
        context 'good value' do
          before { patch 'update', params: { token: user.token, user: { involvements: ['resources', 'outings', 'both_actions'] } } }
          it { expect(result['user']).to include('involvements' => match_array(['outings', 'resources', 'both_actions'])) }
        end
      end

      context 'involvements as an array' do
        context 'good value' do
          before { patch 'update', params: { token: user.token, user: { involvements: ['resources', 'outings', 'both_actions'] } } }
          it { expect(result['user']).to include('involvements' => match_array(['outings', 'resources', 'both_actions'])) }
        end
      end

      context 'involvements as an array' do
        context 'wrong value' do
          before { patch 'update', params: { token: user.token, user: { involvements: ['foo', 'bar'] } } }
          it { expect(response.status).to eq(200) }
          it { expect(result['user']).to include('involvements' => []) }
        end

        context 'wrong value as v7 involvements' do
          before { patch 'update', params: { token: user.token, user: { involvements: ['event_riverain', 'm_informer_riverain'] } } }
          it { expect(response.status).to eq(200) }
          it { expect(result['user']).to include('involvements' => []) }
        end
      end

      # concern_list
      context 'concern_list' do
        context 'good value' do
          before { patch 'update', params: { token: user.token, user: { concern_list: 'sharing_time, material_donations' } } }
          it { expect(result['user']).to include('concerns' => match_array(['material_donations', 'sharing_time'])) }
        end
      end

      context 'concerns as a string' do
        context 'good value' do
          before { patch 'update', params: { token: user.token, user: { concerns: 'sharing_time, material_donations' } } }
          it { expect(result['user']).to include('concerns' => match_array(['material_donations', 'sharing_time'])) }
        end
      end

      context 'concerns as an array' do
        context 'good value when other_concern is missing is also valid' do
          before { patch 'update', params: { token: user.token, user: { concerns: ['sharing_time', 'material_donations', 'services'] } } }
          it { expect(response.status).to eq(200) }
        end
      end

      context 'concerns as an array' do
        context 'good value' do
          before { patch 'update', params: { token: user.token, user: { concerns: ['sharing_time', 'material_donations', 'services'] } } }
          it { expect(result['user']).to include('concerns' => match_array(['material_donations', 'sharing_time', 'services'])) }
        end
      end

      context 'concerns as an array' do
        context 'good value' do
          before { patch 'update', params: { token: user.token, user: { concerns: ['sharing_time', 'material_donations', 'services'] } } }
          it { expect(result['user']).to include('concerns' => match_array(['material_donations', 'sharing_time', 'services'])) }
        end
      end

      context 'concerns as an array' do
        context 'wrong value' do
          before { patch 'update', params: { token: user.token, user: { concerns: ['foo', 'bar'] } } }
          it { expect(response.status).to eq(200) }
          it { expect(result['user']).to include('concerns' => []) }
        end

        context 'wrong value as v7 concerns' do
          before { patch 'update', params: { token: user.token, user: { concerns: ['event_riverain', 'm_informer_riverain'] } } }
          it { expect(response.status).to eq(200) }
          it { expect(result['user']).to include('concerns' => []) }
        end
      end

      # orientation
      context 'orientations' do
        context 'good value' do
          before { patch 'update', params: { token: user.token, user: { orientations: ['guide'] } } }
          it { expect(result['user']).to include('orientations' => ['guide']) }
        end
      end

      context 'updated email is valid' do
        before {
          expect_any_instance_of(SlackServices::SignalUserCreation).not_to receive(:notify)
          patch 'update', params: { token: user.token, user: { email: 'new@e.mail' }, format: :json }
        }
        it { expect(response.status).to eq(200) }
      end

      context 'updated email is blocked' do
        before {
          expect_any_instance_of(SlackServices::SignalUserCreation).to receive(:notify)
          patch 'update', params: { token: user.token, user: { email: 'blocked@email.com' }, format: :json }
        }
        it { expect(response.status).to eq(200) }
      end
    end

    context 'bad authentication' do
      before { patch 'update', params: { token: 'badtoken', user: { email: 'new@e.mail', sms_code: '654321' }, format: :json } }
      it { expect(response.status).to eq(401) }
    end

    describe 'upload avatar' do
      let(:avatar) { fixture_file_upload('avatar.jpg', 'image/jpeg') }

      context 'valid params' do
        it 'sets user avatar key' do
          patch 'update', params: { token: user.token, user: { avatar: avatar }, format: :json }
          expect(user.reload.avatar_key).to eq('avatar')
        end
      end
    end

    describe 'update sms_code' do
      before do
        @request.env['X-API-KEY'] = api_key
        patch 'update', params: { token: user.token, user: { sms_code: '654321' } }
      end

      context 'on mobile' do
        let(:api_key) { 'api_debug' }
        it { expect(response.status).to eq 200 }
      end

      context 'on web' do
        let(:api_key) { 'api_debug_web' }
        it { expect(response.status).to eq 400 }
      end
    end

    describe 'update password' do
      before { patch 'update', params: { token: user.token, user: params } }
      let(:error_message) { JSON.parse(response.body)['error']['message'] }

      context 'valid parameters' do
        let(:params) { {password: 'new password'} }
        it { expect(response.status).to eq 200 }
      end
    end
  end

  describe 'PATCH code' do
    let!(:user) { create :pro_user, sms_code: '123456', avatar_key: 'avatar' }

    describe 'regenerate sms code' do
      before { patch 'code', params: { id: 'me', user: { phone: user.phone }, code: {action: 'regenerate'}, format: :json } }
      it { expect(response.status).to eq(200) }
      it { expect(user.reload.sms_code).to_not eq('123456') }
      it 'renders user' do
        expect(JSON.parse(response.body)).to eq(
          'user' => {
            'phone' => user.phone
          }
        )
      end
    end

    describe 'reset password' do
      before do
        user.update!(password: 'P@ssw0rd')
        @request.env['X-API-KEY'] = api_key
        patch 'code', params: { id: 'me', user: { phone: user.phone }, code: {action: 'regenerate'}, format: :json }
      end

      context 'from web' do
        let(:api_key) { 'api_debug_web' }
        it { expect(user.reload.encrypted_password).to be_nil }
      end

      context 'from mobile' do
        let(:api_key) { 'api_debug' }
        it { expect(user.reload.encrypted_password).to be_present }
      end
    end

    describe 'missing phone' do
      before { patch 'code', params: { id: 'me', user: { foo: 'bar' }, code: {action: 'regenerate'}, format: :json } }
      it { expect(response.status).to eq(400) }
    end

    describe 'unknown phone' do
      before { patch 'code', params: { id: 'me', user: { phone: '0000' }, code: {action: 'regenerate'}, format: :json } }
      it { expect(response.status).to eq(404) }
      it { expect(JSON.parse(response.body)['error']['code']).to eq 'USER_NOT_FOUND' }
    end

    describe 'unknown action' do
      before { patch 'code', params: { id: 'me', user: { phone: user.phone }, code: {action: 'foo'}, format: :json } }
      it { expect(response.status).to eq(400) }
    end
  end

  describe 'POST request_phone_change' do
    let!(:user) { FactoryBot.create(:pro_user, phone: '+33623456789') }

    before { # stubs
      SlackServices::RequestPhoneChange.any_instance.stub(:webhook).with('url') { 'https://www.google.fr' }
      SlackServices::RequestPhoneChange.any_instance.stub(:webhook).with('username') { SlackServices::RequestPhoneChange::USERNAME }
      SlackServices::RequestPhoneChange.any_instance.stub(:webhook).with('channel') { '#channel' }
      SlackServices::RequestPhoneChange.any_instance.stub(:link_to_user) { 'https://www.google.fr' }
      stub_request(:post, 'https://www.google.fr/').to_return(status: 200, body: '', headers: {})
    }

    before { # slack ping
      expect_any_instance_of(Slack::Notifier).to receive(:ping).with({
        attachments: [{ text: 'https://www.google.fr'}, { text: 'Téléphone requis : +33698765432'}, {text: 'Département : '}],
        channel: '#channel',
        text: "<@laure> ou team modération (département : n/a) L'utilisateur John Doe, my@email.com a requis un changement de numéro de téléphone",
        username: SlackServices::RequestPhoneChange::USERNAME
      })
    }

    before { # user_phone_change history
      expect(UserPhoneChange).to receive(:create).with({
        user_id: user.id,
        kind: :request,
        phone_was: '+33623456789',
        phone: '+33698765432',
        email: 'my@email.com'
      })
    }

    it 'request a phone change on Slack' do
      post 'request_phone_change', params: {
        user: { current_phone: '+33623456789', requested_phone: '+33698765432', email: 'my@email.com' },
        format: :json
      }
    end
  end

  describe 'POST create' do
    it 'creates a new user' do
      expect {
        post 'create', params: { user: {phone: '+33612345678'} }
      }.to change { User.count }.by(1)
    end

    context 'valid params' do
      before { post 'create', params: { user: { phone: '+33612345678', travel_distance: 16 } } }
      it { expect(User.last.user_type).to eq('public') }
      it { expect(User.last.community).to eq('entourage') }
      it { expect(User.last.roles).to eq([]) }
      it { expect(User.last.phone).to eq('+33612345678') }
      it { expect(User.last.travel_distance).to eq(16) }
      it {
        expect(JSON.parse(response.body)).to eq(
          'user' => {
            'phone' => User.last.phone
          }
        )
      }

      context 'community support' do
        with_community :pfp
        it { expect(User.last.community).to eq('pfp') }
        it { expect(User.last.roles).to eq([:not_validated]) }
      end
    end

    context 'newsletter_subscription' do
      let(:params) { Hash.new }
      let(:request) { post 'create', params: { user: { phone: '+33612345678', travel_distance: 16, email: 'foo@bar.fr' }.merge(params) } }

      context 'no newsletter_subscription param' do
        before { request }

        it { expect(User.last.newsletter_subscription).to eq(false) }
      end

      context 'newsletter_subscription is false' do
        let(:params) { { newsletter_subscription: 'false' } }

        context do
          before { request }

          it { expect(User.last.newsletter_subscription).to eq(false) }
          it { expect(User.last.email).to eq('foo@bar.fr') }
        end

        context do
          after { request }

          it { expect_any_instance_of(NewsletterServices::Contact).not_to receive(:create) }
        end
      end

      context 'newsletter_subscription is true' do
        let(:params) { { newsletter_subscription: 'true' } }

        context do
          before { request }

          it { expect(User.last.newsletter_subscription).to eq(true) }
          it { expect(response.status).to eq(201) }
        end

        context do
          after { request }

          it { expect_any_instance_of(NewsletterServices::Contact).to receive(:create) }
        end
      end
    end

    context 'already has a user without email' do
      let!(:previous_user) { FactoryBot.create(:public_user, email: nil) }
      before { post 'create', params: { user: {phone: '+33612345678'} } }
      it { expect(response.status).to eq(201) }
    end

    context 'user with Apple formated phone number' do
      before { post 'create', params: { user: {phone: '+337 44 21 94 91'} } }
      it { expect(User.last.phone).to eq('+33744219491') }
    end

    context 'invalid params' do
      it "doesn't create a new user" do
        expect {
          post 'create', params: { user: {phone: '123'} }
        }.to change { User.count }.by(0)
      end

      it 'returns error' do
        post 'create', params: { user: {phone: '123'} }
        user = User.last
        expect(response.status).to eq(400)
        expect(result).to eq({'error'=>{'code'=>'INVALID_PHONE_FORMAT', 'message'=>'Phone devrait être au format +33... ou 06...'}})
      end
    end

    context 'phone already exists' do
      let!(:existing_user) { FactoryBot.create(:public_user, phone: '+33612345678') }
      before { post 'create', params: { user: {phone: '+33612345678'} } }
      it { expect(User.count).to eq(1) }
      it { expect(response.status).to eq(400) }
      it { expect(result).to eq({'error'=>{'code'=>'PHONE_ALREADY_EXIST', 'message'=>"Phone +33612345678 n'est pas disponible"}}) }
    end
  end

  describe 'GET show' do
    let(:partner) { create :partner }
    let(:user) { create :pro_user, partner: partner }

    context 'not signed in' do
      before { get :show, params: { id: user.id } }
      it { expect(response.status).to eq(401) }
    end

    context 'user signed in' do
      context 'get your own profile' do
        before { get :show, params: { id: user.id, token: user.token } }
        it { expect(response.status).to eq(200) }
        it { expect(JSON.parse(response.body)).to eq({
          'user' => {
            'id' => user.id,
            'uuid' => user.id.to_s,
            'email' => user.email,
            'lang' => user.lang,
            'availability' => user.availability,
            'display_name' => 'John D.',
            'first_name' => 'John',
            'last_name' => 'Doe',
            'roles' => ['Association'],
            'about' => nil,
            'token' => user.token,
            'user_type' => 'pro',
            'avatar_url' => nil,
            'has_password' => false,
            'address' => nil,
            'address_2' => nil,
            'stats' => {
               'tour_count' => 0,
               'encounter_count' => 0,
               'entourage_count' => 0,
               'actions_count' => 0,
               'ask_for_help_creation_count' => 0,
               'contribution_creation_count' => 0,
               'events_count' => 0,
               'outings_count' => 0,
               'neighborhoods_count' => 0,
               'good_waves_participation' => false,
            },
            'partner' => {
              'id' => partner.id,
              'name' => 'MyString',
              'image_url' => 'https://foobar.s3.eu-west-1.amazonaws.com/partners/logo/MyString',
              'description' => 'MyDescription',
              'donations_needs' => nil,
              'volunteers_needs' => nil,
              'phone' => nil,
              'address'  =>  '174 rue Championnet, Paris',
              'website_url' => nil,
              'email' => nil,
              'default' => true,
              'user_role_title' => nil},
            'memberships' => [],
            'conversation' => {
              'uuid' => "1_list_#{user.id}"
            },
            'firebase_properties' => {
             'ActionZoneDep' => 'not_set',
             'ActionZoneCP' => 'not_set',
             'Goal' => 'no_set',
             'Interests' => 'none'
            },
            'anonymous' => false,
            'feature_flags' => {
              'organization_admin' => false
            },
            'engaged' => false,
            'goal' => nil,
            'phone' => user.phone,
            'birthday' => false,
            'unread_count' => 0,
            'interests' => [],
            'involvements' => [],
            'orientations' => [],
            'gender' => nil,
            'concerns' => [],
            'travel_distance' => 40,
            'birthdate' => nil,
            'permissions' => {
              'outing' => { 'creation' => true }
            },
            'created_at' => user.created_at.iso8601(3),
          }
        }) }
      end

      context 'when you have an address' do
        let(:user) { create :public_user }
        let!(:address) { create :address, user: user }

        before { get :show, params: { id: 'me', token: user.token } }

        it {
          expect(JSON.parse(response.body)['user']['address']).to eq(
            'latitude' => 1.5,
            'longitude' => 1.5,
            'display_address' => 'Cassis, 75020',
            'position'=>1,
          )
        }
      end

      context "get my profile with 'me' shortcut" do
        before { get :show, params: { id: 'me', token: user.token } }
        it { expect(response.status).to eq(200) }
        it { expect(JSON.parse(response.body)).to eq({
          'user' => {
            'id' => user.id,
            'uuid' => user.id.to_s,
            'email' => user.email,
            'lang' => user.lang,
            'availability' => user.availability,
            'display_name' => 'John D.',
            'first_name' => 'John',
            'last_name' => 'Doe',
            'roles' => ['Association'],
            'about' => nil,
            'token' => user.token,
            'user_type' => 'pro',
            'avatar_url' => nil,
            'has_password' => false,
            'address' => nil,
            'address_2' => nil,
            'stats' => {
               'tour_count' => 0,
               'encounter_count' => 0,
               'entourage_count' => 0,
               'actions_count' => 0,
               'ask_for_help_creation_count' => 0,
               'contribution_creation_count' => 0,
               'events_count' => 0,
               'outings_count' => 0,
               'neighborhoods_count' => 0,
               'good_waves_participation' => false,
            },
            'partner' => {
              'id' => partner.id,
              'name' => 'MyString',
              'image_url' => 'https://foobar.s3.eu-west-1.amazonaws.com/partners/logo/MyString',
              'description' => 'MyDescription',
              'donations_needs' => nil,
              'volunteers_needs' => nil,
              'phone' => nil,
              'address' => '174 rue Championnet, Paris',
              'website_url' => nil,
              'email' => nil,
              'default' => true,
              'user_role_title' => nil},
            'memberships' => [],
            'conversation' => {
              'uuid' => "1_list_#{user.id}"
            },
            'firebase_properties' => {
             'ActionZoneDep' => 'not_set',
             'ActionZoneCP' => 'not_set',
             'Goal' => 'no_set',
             'Interests' => 'none'
            },
            'anonymous' => false,
            'feature_flags' => {
              'organization_admin' => false
            },
            'engaged' => false,
            'goal' => nil,
            'phone' => user.phone,
            'birthday' => false,
            'unread_count' => 0,
            'interests' => [],
            'involvements' => [],
            'orientations' => [],
            'gender' => nil,
            'concerns' => [],
            'travel_distance' => 40,
            'birthdate' => nil,
            'permissions' => {
              'outing' => { 'creation' => true }
            },
            'created_at' => user.created_at.iso8601(3),
          }
        }) }
      end

      context 'get my profile as an anonymous user' do
        let(:user) { AnonymousUserService.create_user($server_community) }
        before { get :show, params: { id: 'me', token: user.token } }
        it { expect(result['user']['placeholders']).to eq ['firebase_properties', 'address', 'address_2'] }
      end

      context 'get someone else profile' do
        let(:other_user) { FactoryBot.create(:pro_user, about: 'about') }
        let!(:conversation) { nil }

        before { get :show, params: { id: other_user.id, token: user.token } }

        it { expect(response.status).to eq(200) }
        it { expect(JSON.parse(response.body)).to eq({
          'user' => {
            'id' => other_user.id,
            'lang' => user.lang,
            'availability' => user.availability,
            'display_name' => 'John D.',
            'first_name' => 'John',
            'last_name' => 'D',
            'roles' => [],
            'about' => 'about',
            'avatar_url' => nil,
            'user_type' => 'pro',
            'birthday' => false,
            'stats' => {
              'tour_count' => 0,
              'encounter_count' => 0,
              'entourage_count' => 0,
              'actions_count' => 0,
              'ask_for_help_creation_count' => 0,
              'contribution_creation_count' => 0,
              'events_count' => 0,
              'outings_count' => 0,
              'neighborhoods_count' => 0,
              'good_waves_participation' => false,
            },
            'engaged' => false,
            'unread_count' => 0,
            'partner' => nil,
            'permissions' => {
              'outing' => { 'creation' => false }
            },
            'interests' => [],
            'involvements' => [],
            'orientations' => [],
            'gender' => nil,
            'concerns' => [],
            'memberships' => [],
            'conversation' => {
              'uuid' => "1_list_#{other_user.id}-#{user.id}"
            },
            'created_at' => other_user.created_at.iso8601(3),
            'address' => nil,
            'address_2' => nil
          }
        }) }

        context 'when the two users have an existing conversation' do
          let!(:conversation) { create :conversation, participants: [user, other_user] }
          it { expect(result['user']['conversation']['uuid']).to eq conversation.uuid_v2 }
        end

        context 'when conversations are disabled' do
          let!(:conversation) {
            expect(ConversationService)
              .to receive(:conversations_allowed?).with(from: user, to: other_user)
              .and_return(false)
          }
          it { expect(result['user']).not_to have_key 'conversation' }
        end
      end

      context 'roles' do
        let(:other_user) { FactoryBot.create(:public_user, targeting_profile: :ambassador) }
        let!(:join_request)  { create :join_request, user: other_user, status: :accepted }
        let!(:join_request2) { create :join_request, user: other_user, status: :pending }
        before { get :show, params: { id: other_user.id, token: user.token } }
        it { expect(JSON.parse(response.body)['user']['roles']).to eq ['Animateur Entourage'] }
        it { expect(JSON.parse(response.body)['user']['memberships']).to eq [] }
      end

      context 'firebase_properties' do
        context 'action zone' do
          let(:user) { create :public_user }

          before { address }
          before { get :show, params: { id: user.id, token: user.token } }

          let(:firebase_properties) { result['user']['firebase_properties'] }

          context 'no action zone' do
            let(:address) { nil }
            it { expect(firebase_properties).to include(
              'ActionZoneDep' => 'not_set',
              'ActionZoneCP'  => 'not_set'
            ) }
          end

          context 'outside of FR' do
            let(:address) { create :address, country: :BE, user: user }
            it { expect(firebase_properties).to include(
              'ActionZoneDep' => 'not_FR',
              'ActionZoneCP'  => 'not_FR'
            ) }
          end

          context 'only department' do
            let(:address) { create :address, country: :FR, postal_code: '69XXX', user: user }
            it { expect(firebase_properties).to include(
              'ActionZoneDep' => '69',
              'ActionZoneCP'  => 'not_set'
            ) }
          end

          context 'full postal code' do
            let(:address) { create :address, country: :FR, postal_code: '75012', user: user }
            it { expect(firebase_properties).to include(
              'ActionZoneDep' => '75',
              'ActionZoneCP'  => '75012'
            ) }
          end
        end
      end
    end
  end

  describe 'DELETE destroy' do
    before { Timecop.freeze(Time.parse('10/10/2010').at_beginning_of_day) }

    let!(:user) { FactoryBot.create(:pro_user, deleted: false, phone: '0612345678', email: 'foo@bar.com') }

    before { delete :destroy, params: { id: user.to_param, token: user.token } }

    it { expect(user.reload.deleted).to be true }
    it { expect(user.reload.phone).to eq('+33612345678-2010-10-10 00:00:00') }
    it { expect(user.reload.email).to eq('foo@bar.com-2010-10-10 00:00:00') }
    it { expect(response.status).to eq(200) }
    it { expect(JSON.parse(response.body)).to have_key('user') }
  end

  describe 'POST #report' do
    let(:reporting_user) { create :public_user }
    let(:reported_user)  { create :public_user }
    let(:result) { JSON.parse(response.body) }

    context 'valid params' do
      before {
        expect_any_instance_of(SlackServices::SignalUser).to receive(:notify)
        post 'report', params: { token: reporting_user.token, id: reported_user.id, user_report: { message: 'message' } }
      }

      it { expect(response.status).to eq 201 }
    end

    context 'valid params with signals but no message' do
      before {
        expect_any_instance_of(SlackServices::SignalUser).to receive(:notify)
        post 'report', params: { token: reporting_user.token, id: reported_user.id, user_report: { message: nil, signals: ['spam'] } }
      }

      it { expect(response.status).to eq 201 }
    end

    context 'invalid signal' do
      before {
        expect_any_instance_of(SlackServices::SignalUser).not_to receive(:notify)
        post 'report', params: { token: reporting_user.token, id: reported_user.id, user_report: { message: nil, signals: ['foo'] } }
      }

      it { expect(response.status).to eq 400 }
      it { expect(result['message']).to eq 'Signal is invalid' }
    end

    context 'missing message without signals' do
      before {
        expect_any_instance_of(SlackServices::SignalUser).not_to receive(:notify)
        post 'report', params: { token: reporting_user.token, id: reported_user.id, user_report: { message: '' } }
      }

      it { expect(response.status).to eq 400 }
      it { expect(result['message']).to eq 'Message is required' }
    end

    context 'empty signals' do
      before {
        expect_any_instance_of(SlackServices::SignalUser).not_to receive(:notify)
        post 'report', params: { token: reporting_user.token, id: reported_user.id, user_report: { message: 'foobar', signals: [''] } }
      }

      it { expect(response.status).to eq 400 }
      it { expect(result['message']).to eq 'Signal is invalid' }
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

    context 'valid params' do
      let(:address) { { place_name: '75012', latitude: 48.835085, longitude: 2.382165 } }
      before { subject }
      it { expect(response.status).to eq 200 }
      it { expect(JSON.parse(response.body)).to eq(
        'address'=>{
          'display_address'=>'75012',
          'latitude'=>48.835085,
          'longitude'=>2.382165,
          'position'=>1,
        },
        'firebase_properties'=>{
          'ActionZoneDep'=>'not_set',
          'ActionZoneCP'=>'not_set',
          'Goal' => 'no_set',
          'Interests' => 'none',
        })
      }
      it { expect(user.reload.address.attributes.symbolize_keys).to include address }
    end

    context 'invalid params' do
      let(:address) { { place_name: nil, latitude: nil, longitude: nil } }
      before { subject }

      shared_examples 'common tests' do
        it { expect(response.status).to eq 400 }
        it { expect(JSON.parse(response.body)).to eq({
          'error'=>{
            'code'=>'CANNOT_UPDATE_ADDRESS',
            'message'=>[
              'Place name doit être rempli(e)',
              'Latitude doit être rempli(e)',
              'Longitude doit être rempli(e)'
            ]
          }
        }) }
        it { expect(Address.count).to eq 0 }
      end

      context 'with a standard user' do
        include_examples 'common tests'
        it { expect(user.reload.address_id).to be_nil }
      end
    end

    context 'with a google place_id' do
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

      context 'when required attributes are missing' do
        let(:address) { { google_place_id: 'some-place-id' } }

        context 'with a standard user' do
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
      end

      context 'when required attributes are present' do
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
        it 'updates the address queries with Google Places data asynchronously' do
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

    context 'create' do
      let(:following) { { partner_id: partner.id, active: true } }
      before { subject }
      it { expect(response.status).to eq 200 }
      it { expect(JSON.parse(response.body)).to eq(
        'following' => {
          'partner_id' => partner.id,
          'active' => true
        }
      )}
      it { expect(Following.where(user: user, partner: partner).pluck(:active)).to eq [true] }
    end

    context 'unfollow' do
      let!(:existing) { create :following, user: user, partner: partner }
      let(:following) { { partner_id: partner.id, active: false } }
      before { subject }
      it { expect(response.status).to eq 200 }
      it { expect(JSON.parse(response.body)).to eq(
        'following' => {
          'partner_id' => partner.id,
          'active' => false
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

    context 'unsubscribe from a specific category' do
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

    context 'unsubscribe from all emails' do
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
end
