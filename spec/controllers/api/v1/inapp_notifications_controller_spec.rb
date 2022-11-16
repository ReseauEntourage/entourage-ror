require 'rails_helper'

describe Api::V1::InappNotificationsController, :type => :controller do
  let(:user) { create :pro_user }

  context 'index' do
    let!(:inapp_notification) { create :inapp_notification }
    let(:result) { JSON.parse(response.body) }

    describe 'not authorized' do
      before { get :index }

      it { expect(response.status).to eq 401 }
    end

    describe 'authorized' do
      before { get :index, params: { token: user.token } }

      context 'does not belong to user' do
        it { expect(response.status).to eq 200 }
        it { expect(result).to have_key('inapp_notifications') }
        it { expect(result['inapp_notifications'].count).to eq(0) }
      end

      context 'belongs to user' do
        let!(:inapp_notification) { create :inapp_notification, user: user }

        it { expect(result['inapp_notifications'].count).to eq(1) }
        it { expect(result['inapp_notifications'][0]['instance']).to eq(inapp_notification.instance) }
        it { expect(result['inapp_notifications'][0]['instance_id']).to eq(inapp_notification.instance_id) }
      end
    end
  end

  context 'destroy' do
    let(:inapp_notification) { create :inapp_notification }
    let(:result) { JSON.parse(response.body) }

    describe 'not authorized' do
      describe 'not logged' do
        before { delete :destroy, params: { id: inapp_notification.id } }

        it { expect(response.status).to eq 401 }
        it { expect(InappNotification.find(inapp_notification.id).completed_at).to be_nil }
      end

      describe 'not the same user' do
        before { delete :destroy, params: { token: user.token, id: inapp_notification.id } }

        it { expect(response.status).to eq 401 }
        it { expect(InappNotification.find(inapp_notification.id).completed_at).to be_nil }
      end
    end

    describe 'authorized' do
      before { delete :destroy, params: { token: user.token, id: inapp_notification.id } }

      let(:inapp_notification) { create :inapp_notification, user: user }

      it { expect(InappNotification.find(inapp_notification.id).completed_at).not_to be_nil }
      it { expect(InappNotification.find(inapp_notification.id).completed_at).to be_a(ActiveSupport::TimeWithZone) }
    end
  end

  context 'count' do
    let(:result) { JSON.parse(response.body) }

    describe 'not authorized' do
      before { get :count }

      it { expect(response.status).to eq 401 }
    end

    describe 'authorized' do
      context 'inapp_notification belongs to user' do
        let!(:inapp_notification) { create :inapp_notification, user: user }

        before { get :count, params: { token: user.token } }

        it { expect(response.status).to eq 200 }
        it { expect(result).to have_key('count') }
        it { expect(result['count']).to eq(1) }
      end

      context 'inapp_notification belongs does not belong to user' do
        let!(:inapp_notification) { create :inapp_notification }

        before { get :count, params: { token: user.token } }

        it { expect(response.status).to eq 200 }
        it { expect(result).to have_key('count') }
        it { expect(result['count']).to eq(0) }
      end
    end
  end
end
