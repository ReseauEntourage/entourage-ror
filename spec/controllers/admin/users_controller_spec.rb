require 'rails_helper'
include AuthHelper

describe Admin::UsersController do

  let(:validated_user_with_avatar) { FactoryBot.create(:public_user, validation_status: 'validated', avatar_key: 'avatar_123') }
  let(:validated_user_without_avatar) { FactoryBot.create(:public_user, validation_status: 'validated', avatar_key: nil) }
  let(:blocked_user) { FactoryBot.create(:public_user, validation_status: 'blocked', avatar_key: 'avatar_456') }

  describe 'GET index' do
    let!(:user) { admin_basic_login }
    let!(:searched) { FactoryBot.create(:public_user, first_name: 'Youri', last_name: 'Gagarine', email: 'youri@gagarine.social', phone: '+33600000000') }

    # found
    context 'like first_name' do
      before { get :index, params: { search: 'Youri'} }
      it { expect(assigns(:users).count).to eq(1) }
      it { expect(assigns(:users).map(&:first_name).uniq).to eq([searched.first_name]) }
    end

    context 'like last_name' do
      before { get :index, params: { search: 'Gagarine'} }
      it { expect(assigns(:users).count).to eq(1) }
      it { expect(assigns(:users).map(&:last_name).uniq).to eq([searched.last_name]) }
    end

    context '= email' do
      before { get :index, params: { search: 'youri@gagarine.social'} }
      it { expect(assigns(:users).count).to eq(1) }
      it { expect(assigns(:users).map(&:email).uniq).to eq([searched.email]) }
    end

    context 'like full_name' do
      before { get :index, params: { search: 'Youri Gagarine'} }
      it { expect(assigns(:users).count).to eq(1) }
      it { expect(assigns(:users).map(&:first_name).uniq).to eq([searched.first_name]) }
    end

    context 'exact phone' do
      before { get :index, params: { search: '+33600000000'} }
      it { expect(assigns(:users).count).to eq(1) }
      it { expect(assigns(:users).map(&:phone).uniq).to eq([searched.phone]) }
    end

    # case insensitive
    context 'like first_name case insensitive' do
      before { get :index, params: { search: 'YOURI'} }
      it { expect(assigns(:users).count).to eq(1) }
      it { expect(assigns(:users).map(&:first_name).uniq).to eq([searched.first_name]) }
    end

    context 'like last_name case insensitive' do
      before { get :index, params: { search: 'GAGARINE'} }
      it { expect(assigns(:users).count).to eq(1) }
      it { expect(assigns(:users).map(&:last_name).uniq).to eq([searched.last_name]) }
    end

    context 'like email case insensitive' do
      before { get :index, params: { search: 'YOURI@GAGARINE.SOCIAL'} }
      it { expect(assigns(:users).count).to eq(1) }
      it { expect(assigns(:users).map(&:email).uniq).to eq([searched.email]) }
    end

    # strip insensitive
    context 'like first_name strip insensitive' do
      before { get :index, params: { search: '  youri  '} }
      it { expect(assigns(:users).count).to eq(1) }
      it { expect(assigns(:users).map(&:first_name).uniq).to eq([searched.first_name]) }
    end

    context 'like last_name strip insensitive' do
      before { get :index, params: { search: '  gagarine  '} }
      it { expect(assigns(:users).count).to eq(1) }
      it { expect(assigns(:users).map(&:last_name).uniq).to eq([searched.last_name]) }
    end

    context 'like email strip insensitive' do
      before { get :index, params: { search: '  youri@gagarine.social  '} }
      it { expect(assigns(:users).count).to eq(1) }
      it { expect(assigns(:users).map(&:email).uniq).to eq([searched.email]) }
    end

    # phone formats
    context 'phone with no country code' do
      before { get :index, params: { search: '0600000000'} }
      it { expect(assigns(:users).count).to eq(1) }
      it { expect(assigns(:users).map(&:phone).uniq).to eq([searched.phone]) }
    end

    context 'phone with spaces and no country code' do
      before { get :index, params: { search: '06 00 00 00 00'} }
      it { expect(assigns(:users).count).to eq(1) }
      it { expect(assigns(:users).map(&:phone).uniq).to eq([searched.phone]) }
    end

    # not found
    context 'not like first_name' do
      before { get :index, params: { search: 'Marie'} }
      it { expect(assigns(:users).count).to eq(0) }
    end

    context 'not like last_name' do
      before { get :index, params: { search: 'Curie'} }
      it { expect(assigns(:users).count).to eq(0) }
    end

    context 'not like email' do
      before { get :index, params: { search: 'marie@curie'} }
      it { expect(assigns(:users).count).to eq(0) }
    end

    context 'different phone' do
      before { get :index, params: { search: '+33700000000'} }
      it { expect(assigns(:users).count).to eq(0) }
    end
  end




  describe 'GET moderate' do
    context 'not signed in' do
      before { get :moderate }
      it { should redirect_to new_session_path(continue: request.fullpath) }
    end

    context 'signed in' do
      let!(:user) { admin_basic_login }
      before { get :moderate }
      it { expect(response.code).to eq('200') }
      it { expect(assigns(:users)).to eq([validated_user_with_avatar]) }
    end
  end

  describe 'PUT update' do
    let!(:admin) { admin_basic_login }
    let!(:user) { FactoryBot.create(:pro_user, first_name: 'John', phone: '+33600112233') }

    context 'common field' do
      before {
        put :update, params: { id: user.id, user: {
          first_name: 'Jane',
          about: 'foo'
        }, user_moderation: { skills: ['Administratif'] } }
        user.reload
      }
      it { expect(user.first_name).to eq('Jane')}
    end

    context 'change phone' do
      before { # user_phone_change history
        expect(UserPhoneChange).to receive(:create).with({
          user_id: user.id,
          admin_id: admin.id,
          kind: :change,
          phone_was: '+33600112233',
          phone: '+33611223344',
          email: user.email
        })
      }

      it {
        put :update, params: { id: user.id, user: {
          phone: '+33611223344',
          about: 'foo'
        }, user_moderation: { skills: ['Administratif'] } }
      }
    end

    context 'did not change phone' do
      before { # user_phone_change history
        expect(UserPhoneChange).not_to receive(:create)
      }

      it {
        put :update, params: { id: user.id, user: {
          phone: user.phone,
          about: 'foo'
        }, user_moderation: { skills: ['Administratif'] } }
      }
    end

    context 'change sms_code' do
      before {
        expect_any_instance_of(UserServices::SMSSender).to receive(:send_welcome_sms).with(
          '123456',
          'regenerate'
        )
      }

      it {
        put :update, params: { id: user.id, user: {
          sms_code_password: '123456',
          about: 'foo'
        }, user_moderation: { skills: ['Administratif'] } }
      }
    end

    context 'change sms_code does not work for invalid password' do
      before {
        expect_any_instance_of(UserServices::SMSSender).not_to receive(:send_welcome_sms)
      }

      it {
        put :update, params: { id: user.id, user: {
          sms_code_password: '12345',
          about: 'foo'
        }, user_moderation: { skills: ['Administratif'] } }
      }
    end

    context 'dit not change sms_code' do
      before {
        expect_any_instance_of(UserServices::SMSSender).not_to receive(:send_welcome_sms)
      }

      it {
        put :update, params: { id: user.id, user: {
          first_name: 'Jane',
          about: 'foo'
        }, user_moderation: { skills: ['Administratif'] } }
      }
    end

    context 'add email_preferences' do
      before {
        expect(EmailPreferencesService).to receive(:update).with(user: user, preferences: { newsletter: '1' })
      }

      it {
        put :update, params: { id: user.id, user: { about: 'foo' }, user_moderation: { skills: ['Administratif'] }, email_preferences: { newsletter: '1'} }
      }
    end

    context 'remove email_preferences' do
      before {
        expect(EmailPreferencesService).to receive(:update).with(user: user, preferences: {})
      }

      it {
        put :update, params: { id: user.id, user: { about: 'foo' }, user_moderation: { skills: ['Administratif'] } }
      }
    end
  end

  describe 'PUT cancel_phone_change_request' do
    let!(:admin) { admin_basic_login }
    let!(:user) { FactoryBot.create(:pro_user) }

    context 'no phone_change request' do
      subject { put :cancel_phone_change_request, params: { id: user.id }}

      it { expect { subject }.to change { UserPhoneChange.count }.by(0) }
    end

    context 'with phone_change request' do
      let!(:change_request) { FactoryBot.create(:user_phone_change_request, user_id: user.id, admin_id: admin.id) }

      subject { put :cancel_phone_change_request, params: { id: user.id }}

      it { expect { subject }.to change { UserPhoneChange.count }.by(1) }
      it { expect(subject && UserPhoneChange.last.kind).to eq('cancel') }
    end
  end

  describe 'PUT banish' do
    context 'not signed in' do
      before { put :banish, params: { id: validated_user_with_avatar.to_param } }
      it { should redirect_to new_session_path }
    end

    context 'signed in' do
      let!(:user) { admin_basic_login }
      before do
        stub_request(:delete, "https://foobar.s3.eu-west-1.amazonaws.com/#{validated_user_with_avatar.avatar_key}").
            to_return(status: 200, body: '', headers: {})
        stub_request(:delete, "https://foobar.s3.eu-west-1.amazonaws.com/300x300/#{validated_user_with_avatar.avatar_key}").
            to_return(status: 200, body: '', headers: {})

        put :banish, params: { id: validated_user_with_avatar.to_param }
      end
      it { should redirect_to edit_admin_user_path(validated_user_with_avatar) }
      it { expect(validated_user_with_avatar.reload.validation_status).to eq('blocked') }
    end
  end

  describe 'PUT block' do
    let!(:admin) { admin_basic_login }
    let!(:user) { FactoryBot.create(:pro_user, validation_status: 'validated') }

    context 'no cnil_explanation' do
      before { put :block, params: { id: user.id, user: { cnil_explanation: nil } } }

      it { should redirect_to edit_block_admin_user_path(user) }
      it { expect(user.reload.validation_status).to eq('validated') }
      it { expect(user.reload.histories.count).to eq(0) }
    end

    context 'with cnil_explanation' do
      before { put :block, params: { id: user.id, user: { cnil_explanation: 'reason' } } }

      it { should redirect_to edit_admin_user_path(user) }
      it { expect(user.reload.validation_status).to eq('blocked') }
      it { expect(user.reload.unblock_at).to be(nil) }
      it { expect(user.reload.histories.count).to eq(1) }
    end
  end

  describe 'PUT temporary_block' do
    let!(:admin) { admin_basic_login }
    let!(:user) { FactoryBot.create(:pro_user, validation_status: 'validated') }

    context 'no cnil_explanation' do
      before { put :temporary_block, params: { id: user.id, user: { cnil_explanation: nil } } }

      it { should redirect_to edit_block_admin_user_path(user) }
      it { expect(user.reload.validation_status).to eq('validated') }
      it { expect(user.reload.histories.count).to eq(0) }
    end

    context 'with cnil_explanation' do
      before { put :temporary_block, params: { id: user.id, user: { cnil_explanation: 'reason' } } }

      it { should redirect_to edit_admin_user_path(user) }
      it { expect(user.reload.validation_status).to eq('blocked') }
      it { expect(user.reload.unblock_at).to be_a_kind_of(Time) }
      it { expect(user.reload.histories.count).to eq(1) }
    end
  end

  describe 'PUT unblock' do
    let!(:admin) { admin_basic_login }
    let!(:user) { FactoryBot.create(:pro_user, validation_status: 'blocked') }

    context 'no cnil_explanation' do
      before { put :unblock, params: { id: user.id, user: { cnil_explanation: nil } } }

      it { should redirect_to edit_block_admin_user_path(user) }
      it { expect(user.reload.validation_status).to eq('blocked') }
      it { expect(user.reload.histories.count).to eq(0) }
    end

    context 'with cnil_explanation' do
      before { put :unblock, params: { id: user.id, user: { cnil_explanation: 'reason' } } }

      it { should redirect_to edit_admin_user_path(user) }
      it { expect(user.reload.validation_status).to eq('validated') }
      it { expect(user.reload.histories.count).to eq(1) }
    end
  end

  describe 'PUT validate' do
    context 'not signed in' do
      before { put :validate, params: { id: blocked_user.to_param } }
      it { should redirect_to new_session_path }
    end

    context 'signed in' do
      let!(:user) { admin_basic_login }
      before { put :validate, params: { id: blocked_user.to_param } }
      it { should redirect_to moderate_admin_users_path }
      it { expect(blocked_user.reload.validation_status).to eq('validated') }
    end
  end
end
