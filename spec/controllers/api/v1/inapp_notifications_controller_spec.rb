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
end
