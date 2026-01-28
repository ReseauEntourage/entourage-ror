require 'rails_helper'

describe Api::V1::Outings::UsersController do
  let(:user) { create(:public_user) }
  let(:manager) { create(:public_user, targeting_profile: :ambassador) }
  let(:outing) { create(:outing, title: 'foobar1') }
  let!(:join_request_organizer) { create(:join_request, user: outing.user, joinable: outing, status: :accepted, role: :organizer) }
  let(:result) { JSON.parse(response.body) }

  describe 'GET index' do
    context 'not signed in' do
      before { get :index, params: { outing_id: outing.to_param } }
      it { expect(response.status).to eq(401) }
    end

    context 'did not join outing' do
      # we can see members even if we did not join
      before { get :index, params: { outing_id: outing.to_param, token: user.token } }
      it { expect(response.status).to eq(200) }
    end

    context 'signed in' do
      let(:user_cancelled) { create(:public_user, first_name: 'cancelled') }
      let(:user_blocked) { create(:public_user, first_name: 'blocked') }

      let!(:join_request) { create(:join_request, user: user, joinable: outing, status: :accepted) }
      let!(:join_request_cancelled) { create(:join_request, user: user_cancelled, joinable: outing, status: :cancelled) }
      let!(:join_request_blocked) { create(:join_request, user: user_blocked, joinable: outing, status: :accepted) }

      before { user_blocked.update_attribute(:validation_status, :blocked) }
      before { get :index, params: { outing_id: outing.to_param, token: user.token } }

      it { expect(result).to have_key('users') }
      it { expect(result['users']).to match_array([{
        'id' => outing.user.id,
        'uuid' => outing.user.uuid,
        'display_name' => 'John D.',
        'role' => 'organizer',
        'group_role' => 'organizer',
        'community_roles' => [],
        'status' => 'accepted',
        'message' => nil,
        'confirmed_at' => nil,
        'participate_at'=>nil,
        'photo_acceptance'=>nil,
        'requested_at' => JoinRequest.where(user: outing.user, joinable: outing).first.created_at.iso8601(3),
        'avatar_url' => nil,
        'partner' => nil,
        'partner_role_title' => nil,
      }, {
        'id' => user.id,
        'uuid' => user.reload.uuid,
        'display_name' => 'John D.',
        'role' => 'participant',
        'group_role' => 'participant',
        'community_roles' => [],
        'status' => 'accepted',
        'message' => nil,
        'confirmed_at' => nil,
        'participate_at'=>nil,
        'photo_acceptance'=>nil,
        'requested_at' => join_request.created_at.iso8601(3),
        'avatar_url' => nil,
        'partner' => nil,
        'partner_role_title' => nil,
      }]) }
    end
  end

  describe 'POST create' do
    context 'not signed in' do
      before { post :create, params: { outing_id: outing.to_param } }
      it { expect(response.status).to eq(401) }
    end

    context 'signed in' do
      context 'first request to join outing' do
        before { post :create, params: { outing_id: outing.to_param, token: user.token, distance: 123.45 } }
        it { expect(JoinRequest.last.distance).to eq(123.45) }
        it { expect(outing.member_ids).to match_array([outing.user_id, user.id]) }
        it { expect(result).to eq(
          'user' => {
            'id' => user.id,
            'uuid' => user.reload.uuid,
            'display_name' => 'John D.',
            'role' => 'participant',
            'group_role' => 'participant',
            'community_roles' => [],
            'status' => 'accepted',
            'message' => nil,
            'confirmed_at' => nil,
            'participate_at'=>nil,
            'photo_acceptance'=>nil,
            'requested_at' => JoinRequest.last.created_at.iso8601(3),
            'avatar_url' => nil,
            'partner' => nil,
            'partner_role_title' => nil,
          }
        )}
      end

      context 'duplicate request to join outing' do
        let!(:join_request) { create(:join_request, user: user, joinable: outing, status: :cancelled) }
        before { post :create, params: { outing_id: outing.to_param, token: user.token } }

        it { expect(outing.member_ids).to match_array([outing.user_id, user.id]) }
        it { expect(result).to eq(
          'user' => {
            'id' => user.id,
            'uuid' => user.reload.uuid,
            'display_name' => 'John D.',
            'role' => 'participant',
            'group_role' => join_request.role,
            'community_roles' => [],
            'status' => 'accepted',
            'message' => nil,
            'confirmed_at' => nil,
            'participate_at'=>nil,
            'photo_acceptance'=>nil,
            'requested_at' => JoinRequest.last.created_at.iso8601(3),
            'avatar_url' => nil,
            'partner' => nil,
            'partner_role_title' => nil,
          }
        )}
      end

      context 'change role to organizer for ambassador' do
        let(:user) { create(:public_user, targeting_profile: 'ambassador') }
        let!(:join_request) { create(:join_request, user: user, joinable: outing) }
        before { post :create, params: { outing_id: outing.to_param, token: user.token, role: :organizer } }

        it { expect(outing.member_ids).to match_array([outing.user_id, user.id]) }
        it { expect(result['user']['role']).to eq('organizer') }
      end

      context 'change role to organizer for not ambassador' do
        let!(:join_request) { create(:join_request, user: user, joinable: outing) }
        before { post :create, params: { outing_id: outing.to_param, token: user.token, role: :organizer } }

        it { expect(outing.member_ids).to match_array([outing.user_id, user.id]) }
        it { expect(result['user']['role']).to eq('participant') }
      end

      context 'change role from organizer to participant for ambassador' do
        let(:user) { create(:public_user, targeting_profile: 'ambassador') }
        let!(:join_request) { create(:join_request, user: user, joinable: outing, role: :organizer) }
        before { post :create, params: { outing_id: outing.to_param, token: user.token, role: :participant } }

        it { expect(outing.member_ids).to match_array([outing.user_id, user.id]) }
        it { expect(result['user']['role']).to eq('participant') }
      end

      context 'change role to participant for ambassador who cancelled its participation' do
        let(:user) { create(:public_user, targeting_profile: 'ambassador') }
        let!(:join_request) { create(:join_request, user: user, joinable: outing, status: :cancelled, role: :organizer) }
        before { post :create, params: { outing_id: outing.to_param, token: user.token } }

        it { expect(outing.member_ids).to match_array([outing.user_id, user.id]) }
        it { expect(result['user']['role']).to eq('participant') }
      end

      context 'change role to organizer for ambassador who cancelled its participation' do
        let(:user) { create(:public_user, targeting_profile: 'ambassador') }
        let!(:join_request) { create(:join_request, user: user, joinable: outing, status: :cancelled, role: :participant) }
        before { post :create, params: { outing_id: outing.to_param, token: user.token, role: :organizer } }

        it { expect(outing.member_ids).to match_array([outing.user_id, user.id]) }
        it { expect(result['user']['role']).to eq('organizer') }
      end

      context 'user has community_roles' do
        let(:user) { create(:public_user, targeting_profile: 'ambassador') }
        before { post :create, params: { outing_id: outing.to_param, token: user.token, distance: 123.45 } }

        it { expect(outing.member_ids).to match_array([outing.user_id, user.id]) }
        it { expect(result['user']['community_roles']).to eq(['Animateur Entourage']) }
      end

      context 'push notification sent' do
        before {
          allow_any_instance_of(PushNotificationTrigger).to receive(:notify)
          expect_any_instance_of(PushNotificationTrigger).to receive(:notify).with(
            sender_id: user.id,
            referent: outing,
            instance: outing,
            users: [outing.user],
            params: {
              object: PushNotificationTrigger::I18nStruct.new(i18n: 'push_notifications.join_request.new'),
              content: PushNotificationTrigger::I18nStruct.new(i18n: 'push_notifications.join_request.create_outing', i18n_args: ['John D.', outing.title, I18n.l(outing.starts_at.to_date)]),
              extra: {
                tracking: :join_request_on_create_to_outing,
                group_type: 'outing',
                joinable_id: outing.id,
                joinable_type: 'Entourage',
                type: 'JOIN_REQUEST_ACCEPTED',
                user_id: user.id
              }
            }
          ).once
        }

        before { post :create, params: { outing_id: outing.to_param, token: user.token, distance: 123.45 } }

        it { expect(response.status).to eq(201) }
      end
    end
  end

  describe 'POST confirm' do
    context 'not signed in' do
      before { post :confirm, params: { outing_id: outing.to_param } }
      it { expect(response.status).to eq(401) }
    end

    context 'signed in' do
      context 'not as participant' do
        before { post :confirm, params: { outing_id: outing.to_param, token: user.token } }

        it { expect(outing.member_ids).to match_array([outing.user_id, user.id]) }
        it { expect(result).to eq(
          'user' => {
            'id' => user.id,
            'uuid' => user.reload.uuid,
            'display_name' => 'John D.',
            'role' => 'participant',
            'group_role' => 'participant',
            'community_roles' => [],
            'status' => 'accepted',
            'message' => nil,
            'requested_at' => JoinRequest.last.created_at.iso8601(3),
            'confirmed_at' => JoinRequest.last.confirmed_at.iso8601(3),
            'participate_at'=>nil,
            'photo_acceptance'=>nil,
            'avatar_url' => nil,
            'partner' => nil,
            'partner_role_title' => nil,
          }
        )}
      end

      context 'as participant' do
        let!(:join_request) { create(:join_request, user: user, joinable: outing, status: :accepted) }

        before { post :confirm, params: { outing_id: outing.to_param, token: user.token } }

        it { expect(outing.member_ids).to match_array([outing.user_id, user.id]) }
        it { expect(result).to eq(
          'user' => {
            'id' => user.id,
            'uuid' => user.reload.uuid,
            'display_name' => 'John D.',
            'role' => 'participant',
            'group_role' => 'participant',
            'community_roles' => [],
            'status' => 'accepted',
            'message' => nil,
            'requested_at' => JoinRequest.last.created_at.iso8601(3),
            'confirmed_at' => JoinRequest.last.confirmed_at.iso8601(3),
            'participate_at'=>nil,
            'photo_acceptance'=>nil,
            'avatar_url' => nil,
            'partner' => nil,
            'partner_role_title' => nil,
          }
        )}
      end
    end
  end

  describe 'POST participate' do
    let(:request) { post :participate, params: { outing_id: outing.to_param, id: user.to_param, token: manager.token } }

    context "requester is not organizer" do
      before { post :participate, params: { outing_id: outing.to_param, id: user.to_param, token: create(:public_user).token } }

      it { expect(response.status).to eq(401) }
    end

    context "manager is not a manager" do
      let(:manager) { create(:public_user) }

      before { request }

      it { expect(response.status).to eq(401) }
    end

    context "not as participant" do
      before { request }

      it { expect(response.status).to eq(201) }
      it { expect(outing.member_ids).to match_array([outing.user_id, user.id]) }
      it { expect(Time.iso8601(result["user"]["participate_at"])).to be_a(Time) }
    end

    context "as participant" do
      let!(:join_request) { create(:join_request, user: user, joinable: outing, status: :accepted) }

      before { request }

      it { expect(response.status).to eq(201) }
      it { expect(outing.member_ids).to match_array([outing.user_id, user.id]) }
      it { expect(Time.iso8601(result["user"]["participate_at"])).to be_a(Time) }
    end
  end

  describe 'POST cancel_participation' do
    let(:request) { post :cancel_participation, params: { outing_id: outing.to_param, id: user.to_param, token: manager.token } }

    context "requester is not organizer" do
      before { post :cancel_participation, params: { outing_id: outing.to_param, id: user.to_param, token: create(:public_user).token } }

      it { expect(response.status).to eq(401) }
    end

    context "manager is not a manager" do
      let(:manager) { create(:public_user) }

      before { request }

      it { expect(response.status).to eq(401) }
    end

    context "not as participant" do
      before { request }

      it { expect(response.status).to eq(201) }
      it { expect(outing.member_ids).to match_array([outing.user_id, user.id]) }
      it { expect(result["user"]["participate_at"]).to be_nil }
    end

    context "as participant" do
      let!(:join_request) { create(:join_request, user: user, joinable: outing, status: :accepted) }

      before { request }

      it { expect(response.status).to eq(201) }
      it { expect(outing.member_ids).to match_array([outing.user_id, user.id]) }
      it { expect(result["user"]["participate_at"]).to be_nil }
    end

    context "as participant with participation_at" do
      let!(:join_request) { create(:join_request, user: user, joinable: outing, status: :accepted, participate_at: Time.zone.now) }

      before { request }

      it { expect(response.status).to eq(201) }
      it { expect(outing.member_ids).to match_array([outing.user_id, user.id]) }
      it { expect(result["user"]["participate_at"]).to be_nil }
    end
  end

  describe 'POST photo_acceptance' do
    let(:request) { post :photo_acceptance, params: { outing_id: outing.to_param, id: user.to_param, token: manager.token } }

    context "requester is not organizer" do
      before { post :photo_acceptance, params: { outing_id: outing.to_param, id: user.to_param, token: create(:public_user).token } }

      it { expect(response.status).to eq(401) }
    end

    context "manager is not a manager" do
      let(:manager) { create(:public_user) }

      before { request }

      it { expect(response.status).to eq(401) }
    end

    context "not as participant" do
      before { request }

      it { expect(response.status).to eq(201) }
      it { expect(outing.member_ids).to match_array([outing.user_id, user.id]) }
      it { expect(result["user"]["photo_acceptance"]).to eq(true) }
    end

    context "as participant" do
      let!(:join_request) { create(:join_request, user: user, joinable: outing, status: :accepted) }

      before { request }

      it { expect(response.status).to eq(201) }
      it { expect(outing.member_ids).to match_array([outing.user_id, user.id]) }
      it { expect(result["user"]["photo_acceptance"]).to eq(true) }
    end
  end

  describe 'POST cancel_photo_acceptance' do
    let(:request) { post :cancel_photo_acceptance, params: { outing_id: outing.to_param, id: user.to_param, token: manager.token } }

    context "requester is not organizer" do
      before { post :cancel_photo_acceptance, params: { outing_id: outing.to_param, id: user.to_param, token: create(:public_user).token } }

      it { expect(response.status).to eq(401) }
    end

    context "manager is not a manager" do
      let(:manager) { create(:public_user) }

      before { request }

      it { expect(response.status).to eq(401) }
    end

    context "not as participant" do
      before { request }

      it { expect(response.status).to eq(201) }
      it { expect(outing.member_ids).to match_array([outing.user_id, user.id]) }
      it { expect(result["user"]["photo_acceptance"]).to eq(false) }
    end

    context "as participant" do
      let!(:join_request) { create(:join_request, user: user, joinable: outing, status: :accepted) }

      before { request }

      it { expect(response.status).to eq(201) }
      it { expect(outing.member_ids).to match_array([outing.user_id, user.id]) }
      it { expect(result["user"]["photo_acceptance"]).to eq(false) }
    end
  end

  describe 'DELETE destroy' do
    context 'not signed in' do
      before { delete :destroy, params: { outing_id: outing.to_param, id: user.id } }
      it { expect(response.status).to eq(401) }
    end

    context 'signed in' do
      context 'quit outing' do
        let!(:my_join_request) { create(:join_request, user: user, joinable: outing, status: :accepted) }

        before { delete :destroy, params: { outing_id: outing.to_param, id: user.id, token: user.token } }
        it { expect(response.status).to eq(200) }
        it { expect(expect(my_join_request.reload.status).to eq('cancelled')) }
        it { expect(result).to eq({
          'user' => {
            'id' => user.id,
            'uuid' => user.reload.uuid,
            'display_name' => 'John D.',
            'role' => 'participant',
            'group_role' => 'participant',
            'community_roles' => [],
            'status' => 'not_requested',
            'message' => nil,
            'confirmed_at' => nil,
            'participate_at'=>nil,
            'photo_acceptance'=>nil,
            'requested_at' => my_join_request.created_at.iso8601(3),
            'avatar_url' => nil,
            'partner' => nil,
            'partner_role_title' => nil,
          }
        })}
      end

      context 'can not quit creator' do
        # @see JoinRequest: can not remove neighborhood creator
        let(:outing) { FactoryBot.create(:outing, title: 'foobar1', user: user) }

        before { delete :destroy, params: { outing_id: outing.to_param, id: user.id, token: user.token } }

        it { expect(response.status).to eq(400) }
        it { expect(result).to have_key('message') }
      end

      context 'can not quit another member' do
        let(:member) { FactoryBot.create(:public_user) }
        let!(:my_join_request) { create(:join_request, user: user, joinable: outing, status: :accepted) }
        let!(:member_join_request) { create(:join_request, user: member, joinable: outing, status: :accepted) }

        before { delete :destroy, params: { outing_id: outing.to_param, id: member.id, token: user.token } }

        it { expect(response.status).to eq(401) }
        it { expect(result).to have_key('message') }
      end

      context "user didn't request to join outing" do
        before { delete :destroy, params: { outing_id: outing.to_param, id: user.id, token: user.token } }

        it { expect(response.status).to eq(401) }
        it { expect(result).to have_key('message') }
      end
    end
  end

  describe 'DELETE destroy on collection' do
    context 'not signed in' do
      before { delete :destroy, params: { outing_id: outing.to_param } }
      it { expect(response.status).to eq(401) }
    end


    context 'signed in' do
      context 'quit outing' do
        let!(:my_join_request) { create(:join_request, user: user, joinable: outing, status: :accepted) }

        before { delete :destroy, params: { outing_id: outing.to_param, token: user.token } }
        it { expect(response.status).to eq(200) }
        it { expect(expect(my_join_request.reload.status).to eq('cancelled')) }
        it { expect(result).to eq({
          'user' => {
            'id' => user.id,
            'uuid' => user.reload.uuid,
            'display_name' => 'John D.',
            'role' => 'participant',
            'group_role' => 'participant',
            'community_roles' => [],
            'status' => 'not_requested',
            'message' => nil,
            'confirmed_at' => nil,
            'participate_at'=>nil,
            'photo_acceptance'=>nil,
            'requested_at' => my_join_request.created_at.iso8601(3),
            'avatar_url' => nil,
            'partner' => nil,
            'partner_role_title' => nil,
          }
        })}
      end
    end
  end
end
