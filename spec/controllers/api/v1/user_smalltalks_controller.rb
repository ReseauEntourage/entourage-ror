require 'rails_helper'

describe Api::V1::UserSmalltalksController, :type => :controller do
  let(:user) { create :pro_user, goal: :offer_help }
  let(:smalltalk) { create :smalltalk }
  let(:user_smalltalk) { create :user_smalltalk, user: user, smalltalk: smalltalk }

  context 'index' do
    before { user_smalltalk }

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

  context 'show' do
    before { user_smalltalk }

    let(:result) { JSON.parse(response.body) }

    describe 'not authorized' do
      before { get :show, params: { id: user_smalltalk.id } }

      it { expect(response.status).to eq 401 }
    end

    describe 'authorized' do
      before { get :show, params: { id: user_smalltalk.id, token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result).to eq({
        "user_smalltalk" => {
          "smalltalk_id" => smalltalk.id,
          "user_gender" => "male",
          "user_profile" => "offer_help",
          "user_latitude" => user.latitude,
          "user_longitude" => user.longitude,
          "match_format" => "one",
          "match_locality" => false,
          "match_gender" => false,
          "match_interest" => false,
          "last_match_computation_at" => nil,
          "matched_at" => nil,
          "deleted_at" => nil,
          "created_at" => user_smalltalk.created_at.iso8601(3),
        }
      })}
    end
  end

  context 'create' do
    let(:user_smalltalk) { build :user_smalltalk }

    let(:fields) { {
      match_format: :many
    } }

    let(:request) { post :create, params: { token: user.token, user_smalltalk: fields, format: :json } }

    let(:subject) { UserSmalltalk.last }
    let(:result) { JSON.parse(response.body) }

    describe 'not authorized' do
      before { post :create }

      it { expect(response.status).to eq 401 }
    end

    describe 'authorized' do
      before { request }

      it { expect(response.status).to eq(201) }

      it { expect(subject.user_latitude).to eq user.latitude }
      it { expect(subject.user_longitude).to eq user.longitude }

      it { expect(result).to have_key("user_smalltalk") }
      it { expect(result['user_smalltalk']['smalltalk_id']).to eq(nil) }
      it { expect(result['user_smalltalk']['match_format']).to eq("many") }
      it { expect(result['user_smalltalk']['user_latitude']).to eq(user.latitude) }
      it { expect(result['user_smalltalk']['user_longitude']).to eq(user.longitude) }
    end
  end

  describe 'update' do
    let(:user_smalltalk) { create :user_smalltalk, user: user, smalltalk: smalltalk, match_format: :one }
    let(:result) { JSON.parse(response.body) }
    let(:subject) { UserSmalltalk.find(user_smalltalk.id) }

    context "not signed in" do
      before { patch :update, params: { id: user_smalltalk.to_param, user_smalltalk: { match_format: :many } } }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      before { patch :update, params: { id: user_smalltalk.to_param, user_smalltalk: { match_format: :many } } }

      context "user is not creator" do
        let(:user_smalltalk) { create :user_smalltalk, user: create(:pro_user), smalltalk: smalltalk, match_format: :one }

        before { patch :update, params: { id: user_smalltalk.to_param, user_smalltalk: { match_format: :many }, token: user.token } }
        it { expect(response.status).to eq(401) }
      end

      context "user is creator" do
        before { patch :update, params: { id: user_smalltalk.to_param, user_smalltalk: { match_format: "many" }, token: user.token } }

        it { expect(response.status).to eq(200) }
        it { expect(result["user_smalltalk"]["match_format"]).to eq("many") }
      end
    end
  end
end
