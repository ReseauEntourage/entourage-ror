require 'rails_helper'

describe Api::V1::UserApplicationsController do
  let(:user) { FactoryBot.create(:public_user) }

  def random_token base, length
    rand(base**length).to_s(base)
  end

  describe 'PUT update' do
    subject { JSON.parse(response.body) }

    context 'not signed in' do
      before { get :update }
      it { expect(response.status).to eq(401) }
    end

    context 'signed in' do
      context 'no application parameter' do
        before { get :update, params: { token: user.token } }

        it { expect(response.status).to eq(400) }
        it { expect(subject).to have_key('error') }
        it { expect(subject['error']['code']).to eq('PARAMETER_MISSING') }
      end

      context 'with application parameter' do
        before { get :update, params: { token: user.token, application: { push_token: random_token(10, 64) } } }

        it { expect(response.status).to eq(400) }
        it { expect(subject).to have_key('message') }
        it { expect(subject).to have_key('reasons') }
      end

      context 'with all parameters' do
        before { get :update, params: { token: user.token, application: { push_token: random_token(10, 64), version: 1, device_os: 2 } } }

        it { expect(response.status).to eq(204) }
        it { expect(response.body).to eq('') }
      end
    end
  end

  describe 'DELETE destroy' do
    subject { JSON.parse(response.body) }

    context 'not signed in' do
      before { delete :destroy }
      it { expect(response.status).to eq(401) }
    end

    context 'signed in' do
      context 'no application parameter' do
        before { delete :destroy, params: { token: user.token } }

        it { expect(response.status).to eq(400) }
        it { expect(subject).to have_key('error') }
        it { expect(subject['error']['code']).to eq('PARAMETER_MISSING') }
      end
    end

    context 'with application parameter' do
      before { delete :destroy, params: { token: user.token, application: { push_token: random_token(10, 64) } } }

      it { expect(response.status).to eq(204) }
    end

    context 'further tests' do
      pending "add some examples to (or delete) #{__FILE__}"
    end
  end
end
