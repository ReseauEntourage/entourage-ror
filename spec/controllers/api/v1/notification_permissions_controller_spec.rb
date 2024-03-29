require 'rails_helper'

describe Api::V1::NotificationPermissionsController, :type => :controller do
  render_views

  let(:user) { create :pro_user }

  context 'index' do
    let(:result) { JSON.parse(response.body) }

    describe 'not authorized' do
      before { get :index }

      it { expect(response.status).to eq 401 }
    end

    describe 'authorized' do
      describe 'configured' do
        let!(:notification_permission) { create :notification_permission, user: user, permissions: {
          neighborhood: true,
          outing: true,
          chat_message: false,
          action: false
        } }

        before { get :index, params: { token: user.token } }

        it { expect(response.status).to eq 200 }
        it { expect(result).to have_key('notification_permissions') }
        it { expect(result['notification_permissions']).to eq({
          "neighborhood" => true,
          "outing" => true,
          "chat_message" => false,
          "action" => false
        }) }
      end

      describe 'not configured' do
        before { get :index, params: { token: user.token } }

        it { expect(response.status).to eq 200 }
        it { expect(result).to have_key('notification_permissions') }
        it { expect(result['notification_permissions']).to eq({
          "neighborhood" => true,
          "outing" => true,
          "chat_message" => true,
          "action" => true
        }) }
      end
    end
  end

  context 'create' do
    let(:request) { post :create, params: { token: user.token, notification_permissions: {
      neighborhood: true,
      outing: true
    }, format: :json } }

    let(:subject) { NotificationPermission.last }
    let(:result) { JSON.parse(response.body) }

    describe 'not authorized' do
      before { post :create }

      it { expect(response.status).to eq 401 }
    end

    describe 'authorized' do
      describe 'create from not existing permissions' do
        before { request }

        it { expect(response.status).to eq(201) }
        it { expect(subject.permissions).to eq({
          "neighborhood" => true,
          "outing" => true
        }) }
      end

      describe 'create from existing permissions' do
        let!(:notification_permission) { create :notification_permission, user: user, permissions: {
          neighborhood: false,
          outing: true,
          chat_message: false,
          action: false,
        } }

        before { request }

        it { expect(response.status).to eq(201) }
        it { expect(subject.permissions).to eq({
          "neighborhood" => true,
          "outing" => true,
          "chat_message" => false,
          "action" => false,
        }) }
      end
    end
  end
end
