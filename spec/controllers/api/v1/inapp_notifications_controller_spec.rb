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
      let(:request) { get :index, params: { token: user.token } }

      context 'does not belong to user' do
        before { request }

        it { expect(response.status).to eq 200 }
        it { expect(result).to have_key('inapp_notifications') }
        it { expect(result['inapp_notifications'].count).to eq(0) }
      end

      context 'belongs to user' do
        let!(:inapp_notification) { create :inapp_notification, user: user }

        before { request }

        it { expect(result['inapp_notifications'].count).to eq(1) }
        it { expect(result['inapp_notifications'][0]['instance']).to eq(inapp_notification.instance) }
        it { expect(result['inapp_notifications'][0]['instance_id']).to eq(inapp_notification.instance_id) }
        it { expect(result['inapp_notifications'][0]['image_url']).to eq(nil) }
      end

      context 'displayed inapp_notifications is not updated' do
        before { Timecop.freeze(Time.now) }

        let(:a_minute_ago) { 1.minute.ago }
        let!(:inapp_notification) { create :inapp_notification, user: user, displayed_at: a_minute_ago }

        before { request }

        it { expect(inapp_notification.reload.displayed_at.iso8601(3)).to eq(a_minute_ago.iso8601(3)) }
      end

      context 'not_displayed inapp_notifications is updated' do
        before { Timecop.freeze(Time.now) }

        let!(:inapp_notification) { create :inapp_notification, user: user, displayed_at: nil }

        before { request }

        it { expect(inapp_notification.reload.displayed_at.iso8601(3)).to eq(Time.zone.now.iso8601(3)) }
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

      context 'inapp_notification has already been displayed' do
        let!(:inapp_notification) { create :inapp_notification, user: user, displayed_at: Time.now }

        before { get :count, params: { token: user.token } }

        it { expect(response.status).to eq 200 }
        it { expect(result).to have_key('count') }
        it { expect(result['count']).to eq(0) }
      end
    end
  end
end
