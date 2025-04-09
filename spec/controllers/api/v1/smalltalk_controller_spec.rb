require 'rails_helper'

describe Api::V1::SmalltalksController, :type => :controller do
  let(:user) { create :pro_user, goal: :offer_help }
  let(:smalltalk) { create :smalltalk, participants: [user] }

  context 'index' do
    before { smalltalk }

    let(:result) { JSON.parse(response.body) }

    describe 'not authorized' do
      let(:smalltalk) { create :smalltalk }

      before { get :index }

      it { expect(response.status).to eq 401 }
    end

    describe 'authorized' do
      before { get :index, params: { token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result).to have_key('smalltalks') }
      it { expect(result['smalltalks'].count).to eq(1) }
      it { expect(result['smalltalks'][0]['uuid_v2']).to eq(smalltalk.uuid_v2) }
    end
  end

  context 'show' do
    before { smalltalk }

    let(:result) { JSON.parse(response.body) }

    describe 'not authorized' do
      before { get :show, params: { id: smalltalk.id } }

      it { expect(response.status).to eq 401 }
    end

    describe 'authorized' do
      before { get :show, params: { id: smalltalk.id, token: user.token } }

      context 'not a member' do
        let(:smalltalk) { create :smalltalk }

        it { expect(response.status).to eq 401 }
      end

      context 'member' do
        it { expect(response.status).to eq 200 }
        it { expect(result).to eq({
          "smalltalk" => {
            "uuid_v2" => smalltalk.uuid_v2,
            "number_of_people" => 1
          }
        })}
      end
    end
  end
end
