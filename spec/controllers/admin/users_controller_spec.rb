require 'rails_helper'
include AuthHelper

describe Admin::UsersController do

  let(:validated_user_with_avatar) { FactoryBot.create(:public_user, validation_status: "validated", avatar_key: "avatar_123") }
  let(:validated_user_without_avatar) { FactoryBot.create(:public_user, validation_status: "validated", avatar_key: nil) }
  let(:blocked_user) { FactoryBot.create(:public_user, validation_status: "blocked", avatar_key: "avatar_456") }

  describe 'GET moderate' do
    context "not signed in" do
      before { get :moderate }
      it { should redirect_to new_session_path(continue: request.fullpath) }
    end

    context "signed in" do
      let!(:user) { admin_basic_login }
      before { get :moderate }
      it { expect(response.code).to eq("200") }
      it { expect(assigns(:users)).to eq([validated_user_with_avatar]) }
    end
  end

  describe 'PUT update' do
    let!(:admin) { admin_basic_login }
    let!(:user) { FactoryBot.create(:pro_user, first_name: "John", phone: '+33600112233') }

    context "common field" do
      before {
        put :update, params: { id: user.id, user: {
          first_name: "Jane",
          about: 'foo'
        }, user_moderation: { skills: ['Administratif'] } }
        user.reload
      }
      it { expect(user.first_name).to eq("Jane")}
    end

    context "change phone" do
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

    context "did not change phone" do
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

    context "change sms_code" do
      before {
        expect_any_instance_of(UserServices::SMSSender).to receive(:send_welcome_sms).with(
          '123456',
          'regenerate'
        )
      }

      it {
        put :update, params: { id: user.id, user: {
          sms_code: '123456',
          about: 'foo'
        }, user_moderation: { skills: ['Administratif'] } }
      }
    end

    context "dit not change sms_code" do
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
  end

  describe "PUT cancel_phone_change_request" do
    let!(:admin) { admin_basic_login }
    let!(:user) { FactoryBot.create(:pro_user) }

    context "no phone_change request" do
      subject { put :cancel_phone_change_request, params: { id: user.id }}
      it { expect(lambda { subject }).to change { UserPhoneChange.count }.by(0) }
    end

    context "with phone_change request" do
      let!(:change_request) { FactoryBot.create(:user_phone_change_request, user_id: user.id, admin_id: admin.id) }

      subject { put :cancel_phone_change_request, params: { id: user.id }}
      it { expect(lambda { subject }).to change { UserPhoneChange.count }.by(1) }
      it { expect(subject && UserPhoneChange.last.kind).to eq('cancel') }
    end
  end

  describe 'PUT banish' do
    context "not signed in" do
      before { put :banish, params: { id: validated_user_with_avatar.to_param } }
      it { should redirect_to new_session_path }
    end

    context "signed in" do
      let!(:user) { admin_basic_login }
      before(:each) do
        stub_request(:delete, "https://foobar.s3.eu-west-1.amazonaws.com/#{validated_user_with_avatar.avatar_key}").
            to_return(:status => 200, :body => "", :headers => {})
        stub_request(:delete, "https://foobar.s3.eu-west-1.amazonaws.com/300x300/#{validated_user_with_avatar.avatar_key}").
            to_return(:status => 200, :body => "", :headers => {})

        put :banish, params: { id: validated_user_with_avatar.to_param }
      end
      it { should redirect_to moderate_admin_users_path(validation_status: "blocked") }
      it { expect(validated_user_with_avatar.reload.validation_status).to eq("blocked") }
    end
  end

  describe 'PUT block' do
    let!(:admin) { admin_basic_login }
    let!(:user) { FactoryBot.create(:pro_user, validation_status: "validated") }

    context "no cnil_explanation" do
      before { put :block, params: { id: user.id, user: { cnil_explanation: nil } } }

      it { should redirect_to edit_block_admin_user_path(user) }
      it { expect(user.reload.validation_status).to eq("validated") }
      it { expect(user.reload.histories.count).to eq(0) }
    end

    context "with cnil_explanation" do
      before { put :block, params: { id: user.id, user: { cnil_explanation: 'reason' } } }

      it { should redirect_to edit_admin_user_path(user) }
      it { expect(user.reload.validation_status).to eq("blocked") }
      it { expect(user.reload.unblock_at).to be(nil) }
      it { expect(user.reload.histories.count).to eq(1) }
    end
  end

  describe 'PUT temporary_block' do
    let!(:admin) { admin_basic_login }
    let!(:user) { FactoryBot.create(:pro_user, validation_status: "validated") }

    context "no cnil_explanation" do
      before { put :temporary_block, params: { id: user.id, user: { cnil_explanation: nil } } }

      it { should redirect_to edit_block_admin_user_path(user) }
      it { expect(user.reload.validation_status).to eq("validated") }
      it { expect(user.reload.histories.count).to eq(0) }
    end

    context "with cnil_explanation" do
      before { put :temporary_block, params: { id: user.id, user: { cnil_explanation: 'reason' } } }

      it { should redirect_to edit_admin_user_path(user) }
      it { expect(user.reload.validation_status).to eq("blocked") }
      it { expect(user.reload.unblock_at).to be_a_kind_of(Time) }
      it { expect(user.reload.histories.count).to eq(1) }
    end
  end

  describe 'PUT unblock' do
    let!(:admin) { admin_basic_login }
    let!(:user) { FactoryBot.create(:pro_user, validation_status: "blocked") }

    context "no cnil_explanation" do
      before { put :unblock, params: { id: user.id, user: { cnil_explanation: nil } } }

      it { should redirect_to edit_block_admin_user_path(user) }
      it { expect(user.reload.validation_status).to eq("blocked") }
      it { expect(user.reload.histories.count).to eq(0) }
    end

    context "with cnil_explanation" do
      before { put :unblock, params: { id: user.id, user: { cnil_explanation: 'reason' } } }

      it { should redirect_to edit_admin_user_path(user) }
      it { expect(user.reload.validation_status).to eq("validated") }
      it { expect(user.reload.histories.count).to eq(1) }
    end
  end

  describe 'PUT validate' do
    context "not signed in" do
      before { put :validate, params: { id: blocked_user.to_param } }
      it { should redirect_to new_session_path }
    end

    context "signed in" do
      let!(:user) { admin_basic_login }
      before { put :validate, params: { id: blocked_user.to_param } }
      it { should redirect_to moderate_admin_users_path(validation_status: "validated") }
      it { expect(blocked_user.reload.validation_status).to eq("validated") }
    end
  end

  describe "experimental_pending_request_reminder" do
    context "signed in" do
      let!(:user) { admin_basic_login }
      before { post :experimental_pending_request_reminder, params: { id: user.to_param } }
      it { should redirect_to root_path }
    end
  end
end
