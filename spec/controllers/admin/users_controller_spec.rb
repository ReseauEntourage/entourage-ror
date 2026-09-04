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

  describe 'GET index with profile=entourage_volunteer' do
    let!(:admin) { admin_basic_login }
    let!(:staff_partner) { FactoryBot.create(:partner, staff: true) }
    let!(:ambassador) { FactoryBot.create(:public_user, targeting_profile: 'ambassador') }
    let!(:riverain) { FactoryBot.create(:public_user, goal: 'offer_help') }

    before { get :index, params: { profile: 'entourage_volunteer' } }

    it { expect(assigns(:users)).to contain_exactly(ambassador) }
  end

  describe 'GET index association column' do
    let!(:admin) { admin_basic_login }
    let!(:partner) { FactoryBot.create(:partner, name: 'Croix-Rouge') }
    let!(:with_partner) { FactoryBot.create(:public_user, first_name: 'Ada', partner: partner) }
    let!(:without_partner) { FactoryBot.create(:public_user, first_name: 'Bob') }

    before { get :index, params: { search: with_partner.first_name } }

    it { expect(assigns(:users).map(&:partner)).to eq([partner]) }
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
        expect_any_instance_of(UserServices::SmsSender).to receive(:send_welcome_sms).with(
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
        expect_any_instance_of(UserServices::SmsSender).not_to receive(:send_welcome_sms)
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
        expect_any_instance_of(UserServices::SmsSender).not_to receive(:send_welcome_sms)
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

  describe 'POST bulk_block' do
    let!(:admin) { admin_basic_login }
    let!(:user1) { FactoryBot.create(:pro_user, validation_status: 'validated') }
    let!(:user2) { FactoryBot.create(:pro_user, validation_status: 'validated') }

    context 'without cnil_explanation' do
      before { post :bulk_block, params: { user_ids: [user1.id, user2.id], cnil_explanation: '' } }

      it { expect(user1.reload.validation_status).to eq('validated') }
      it { expect(user2.reload.validation_status).to eq('validated') }
    end

    context 'without any selected user' do
      before { post :bulk_block, params: { user_ids: [], cnil_explanation: 'raison' } }

      it { expect(user1.reload.validation_status).to eq('validated') }
    end

    context 'with cnil_explanation and selected users' do
      before { post :bulk_block, params: { user_ids: [user1.id, user2.id], cnil_explanation: 'raison' } }

      it { expect(user1.reload.validation_status).to eq('blocked') }
      it { expect(user2.reload.validation_status).to eq('blocked') }
      it { expect(user1.reload.histories.count).to eq(1) }
    end
  end

  describe 'GET index with postal_code_start_any' do
    let!(:admin) { admin_basic_login }
    let!(:paris_user) { FactoryBot.create(:public_user, community: admin.community) }
    let!(:paris_address) { FactoryBot.create(:address, user: paris_user, postal_code: '75001', country: 'FR') }
    let!(:lyon_user) { FactoryBot.create(:public_user, community: admin.community) }
    let!(:lyon_address) { FactoryBot.create(:address, user: lyon_user, postal_code: '69001', country: 'FR') }

    before { get :index, params: { q: { postal_code_start_any: ['75', '69'] } } }

    it { expect(assigns(:users)).to include(paris_user, lyon_user) }
  end

  describe 'GET timeline' do
    let!(:admin) { admin_basic_login }
    let!(:user) { FactoryBot.create(:public_user) }
    let!(:entourage) { FactoryBot.create(:entourage, user: user) }

    before { get :timeline, params: { id: user.id } }

    it { expect(response).to be_successful }
    it { expect(assigns(:timeline).map { |i| i[:record] }).to include(entourage) }
  end

  describe 'GET index engagement badge' do
    let!(:admin) { admin_basic_login }
    let!(:user) { FactoryBot.create(:public_user) }

    before { get :index }

    it { expect(assigns(:users)).to include(user) }
    it { expect { assigns(:users).each(&:engagement) }.not_to raise_error }
  end

  describe 'rendering (regression: missing partial / template errors)' do
    render_views

    let!(:admin) { admin_basic_login }
    let!(:partner) { FactoryBot.create(:partner) }
    let!(:user) { FactoryBot.create(:public_user, partner: partner) }
    let!(:entourage) { FactoryBot.create(:entourage, user: user) }
    let!(:note) { FactoryBot.create(:admin_note, notable: user, author: admin) }

    before do
      # _header.html.erb links to Salesforce; stub the live API call, unrelated to what's under test here
      allow_any_instance_of(User).to receive(:sf).and_return(double(url: nil))
    end

    it 'renders index' do
      get :index
      expect(response).to be_successful
    end

    it 'renders edit (fiche header: notes tab, timeline tab, engagement badge)' do
      get :edit, params: { id: user.id }
      expect(response).to be_successful
    end

    it 'renders notes' do
      get :notes, params: { id: user.id }
      expect(response).to be_successful
    end

    it 'renders timeline' do
      get :timeline, params: { id: user.id }
      expect(response).to be_successful
    end
  end
end
