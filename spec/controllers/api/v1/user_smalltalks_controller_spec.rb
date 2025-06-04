require 'rails_helper'

describe Api::V1::UserSmalltalksController, :type => :controller do
  let(:user) { create :pro_user, goal: :offer_help }
  let(:smalltalk) { create :smalltalk, participants: [user] }
  let(:user_smalltalk) { create :user_smalltalk, user: user, smalltalk: smalltalk, member_status: :accepted }

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
          "id" => user_smalltalk.id,
          "uuid_v2" => user_smalltalk.uuid_v2,
          "smalltalk_id" => smalltalk.id,
          "match_format" => "one",
          "match_locality" => false,
          "match_gender" => false,
          "has_matched_format" => nil,
          "has_matched_gender" => nil,
          "has_matched_locality" => nil,
          "has_matched_interest" => nil,
          "unmatch_count" => nil,
          "last_match_computation_at" => nil,
          "matched_at" => nil,
          "deleted_at" => nil,
          "created_at" => user_smalltalk.created_at.iso8601(3),
          "user" => {
            "id" => user.id,
            "lang" => user.lang,
            "display_name" => "John D.",
            "avatar_url" => nil,
            "community_roles" => []
          },
          "smalltalk" => {
            "id" => smalltalk.id,
            "uuid_v2" => smalltalk.uuid_v2,
            "type" => "smalltalk",
            "name" => "Nouveau message",
            "subname" => nil,
            "image_url" => nil,
            "members_count" => 1,
            "last_message" => nil,
            "number_of_unread_messages" => nil,
            "has_personal_post" => nil,
            "members" => [
              {
                "id" => user.id,
                "lang" => "fr",
                "display_name" => "John D.",
                "avatar_url" => nil,
                "community_roles" => []
              }
            ],
            "meeting_url" => "https://meet.google.com/stubbed-meet-link",
          }
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

  describe 'POST #match' do
    let(:user_smalltalk) { create(:user_smalltalk, user: user) }
    let(:user_smalltalk_2) { create(:user_smalltalk, user: create(:user), smalltalk: smalltalk) }

    context 'quand un match est trouvé' do
      let(:smalltalk) { create(:smalltalk) }

      before do
        allow_any_instance_of(UserSmalltalk).to receive(:find_match).and_return(user_smalltalk_2)
      end

      it 'renvoie match: true et le smalltalk_id' do
        post :match, params: { id: user_smalltalk.id, token: user.token }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['match']).to eq(true)
        expect(json['smalltalk_id']).to eq(smalltalk.id)
      end
    end

    context 'quand aucun match n’est trouvé' do
      before do
        allow_any_instance_of(UserSmalltalk).to receive(:find_match).and_return(nil)
      end

      it 'renvoie match: false et smalltalk_id nil' do
        post :match, params: { id: user_smalltalk.id, token: user.token }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['match']).to eq(false)
        expect(json['smalltalk_id']).to be_nil
      end
    end
  end

  context 'destroy' do
    before { user_smalltalk }

    let(:result) { UserSmalltalk.unscoped.find(user_smalltalk.id) }

    describe 'not authorized' do
      before { delete :destroy, params: { id: user_smalltalk.id } }

      it { expect(response.status).to eq 401 }
      it { expect(result.deleted_at).to be_nil }
    end

    describe 'not authorized cause should be creator' do
      let(:user_smalltalk) { create :user_smalltalk, user: create(:pro_user) }

      before { delete :destroy, params: { id: user_smalltalk.id, token: user.token } }

      it { expect(response.status).to eq 401 }
      it { expect(result.deleted_at).to be_nil }
    end

    describe 'authorized' do
      let(:creator) { user }

      before { delete :destroy, params: { id: user_smalltalk.id, token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result.deleted_at).not_to be_nil }
    end
  end
end
