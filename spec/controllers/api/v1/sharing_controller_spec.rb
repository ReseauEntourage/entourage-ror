require 'rails_helper'

describe Api::V1::SharingController do
  let(:user) { FactoryBot.create(:offer_help_user) }

  describe 'GET groups' do
    subject { JSON.parse(response.body) }

    context 'not signed in' do
      before { get :groups }
      it { expect(response.status).to eq(401) }
    end

    context 'signed in' do
      before { get :groups, params: { token: user.token } }

      it { expect(subject).to have_key('sharing') }
    end
  end
end
