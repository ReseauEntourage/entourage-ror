require 'rails_helper'

describe Api::V1::NotificationPermissionsController, :type => :controller do
  render_views

  let(:user) { create :pro_user }

  context 'index' do
    let!(:notification_permission) { create :notification_permission, user: user, permissions: {
      neighborhood: true,
      outing: true,
      private_chat_message: false
    } }
    let(:result) { JSON.parse(response.body) }

    describe 'not authorized' do
      before { get :index }

      it { expect(response.status).to eq 401 }
    end

    describe 'authorized' do
      before { get :index, params: { token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result).to have_key('notification_permissions') }
      it { expect(result['notification_permissions']).to eq({
        "neighborhood" => true,
        "outing" => true,
        "private_chat_message" => false
      }) }
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
      before { request }

      it { expect(response.status).to eq(201) }
      it { expect(subject.permissions).to eq({
        "neighborhood" => "true",
        "outing" => "true"
      }) }
    end
  end
end
