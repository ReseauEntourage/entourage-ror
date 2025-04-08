require 'rails_helper'

describe Api::V1::UserSmalltalksController, :type => :controller do
  let(:user) { create :pro_user }

  context 'index' do
    let(:smalltalk) { create :smalltalk }
    let!(:user_smalltalks) { create :user_smalltalk, user: user, smalltalk: smalltalk }
    let(:result) { JSON.parse(response.body) }

    describe 'not authorized' do
      before { get :index }

      it { expect(response.status).to eq 401 }
    end

    describe 'authorized' do
      before { get :index, params: { token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result).to have_key('user_smalltalks') }
      it { expect(result['user_smalltalks'].count).to eq(1) }
      it { expect(result['user_smalltalks'][0]['smalltalk_id']).to eq(smalltalk.id) }
    end
  end
end
