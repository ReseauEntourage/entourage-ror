require 'rails_helper'

describe Api::V1::UserBlockedUsersController, :type => :controller do
  render_views

  let(:user) { create :pro_user }
  let(:alice) { create :pro_user }
  let(:bob) { create :pro_user }
  let(:charlie) { create :pro_user }

  let(:result) { JSON.parse(response.body) }

  context 'index' do
    let!(:user_blocked_user_1) { create :user_blocked_user, user: user, blocked_user: alice }
    let!(:user_blocked_user_2) { create :user_blocked_user, user: user, blocked_user: bob }
    let!(:user_blocked_user_3) { create :user_blocked_user, user: charlie, blocked_user: user }

    describe 'not authorized' do
      before { get :index }

      it { expect(response.status).to eq(401) }
    end

    describe 'authorized' do
      before { get :index, params: { token: user.token } }

      it { expect(response.status).to eq(200) }
      it { expect(result).to eq({
        "user_blocked_users" => [{
          "user" => {
            "id" => user.id,
            "display_name" => "John D.",
            "avatar_url" => nil,
            "community_roles" => [],
          },
          "blocked_user" => {
            "id" => alice.id,
            "display_name" => "John D.",
            "avatar_url" => nil,
            "community_roles" => [],
          },
        }, {
          "user" => {
            "id" => user.id,
            "display_name" => "John D.",
            "avatar_url" => nil,
            "community_roles" => [],
          },
          "blocked_user" => {
            "id" => bob.id,
            "display_name" => "John D.",
            "avatar_url" => nil,
            "community_roles" => [],
          },
        }]
      })}
    end
  end

  context 'show' do
    let!(:user_blocked_user_1) { create :user_blocked_user, user: user, blocked_user: alice }
    let!(:user_blocked_user_2) { create :user_blocked_user, user: user, blocked_user: bob }

    describe 'not authorized' do
      before { get :show, params: { id: alice.id } }

      it { expect(response.status).to eq 401 }
      it { expect(user.blocked_user_ids).to match_array([alice.id, bob.id]) }
    end

    describe 'authorized' do
      context 'user is blocked' do
        before { get :show, params: { token: user.token, id: alice.id } }

        it { expect(response.status).to eq 200 }
        it { expect(result).to eq({
          "user_blocked_user" => {
            "user" => {
              "id" => user.id,
              "display_name" => "John D.",
              "avatar_url" => nil,
              "community_roles" => [],
            },
            "blocked_user" => {
              "id" => alice.id,
              "display_name" => "John D.",
              "avatar_url" => nil,
              "community_roles" => [],
            },
          }
        })}
      end

      context 'user is not blocked' do
        before { get :show, params: { token: user.token, id: charlie.id } }

        it { expect(response.status).to eq 200 }
        it { expect(result).to eq({
          "user_blocked_user" => {}
        }) }
      end
    end
  end

  context 'create' do
    describe 'not authorized' do
      before { post :create }

      it { expect(response.status).to eq 401 }
    end

    describe 'authorized' do
      let(:request) { post :create, params: { token: user.token, format: :json }.merge(params) }

      context 'unique blocked_user_id' do
        let(:params) { { blocked_user_id: alice.id } }

        before { request }

        it { expect(response.status).to eq(201) }
        it { expect(result).to eq({
          "user_blocked_user" => {
            "user" => {
              "id" => user.id,
              "display_name" => "John D.",
              "avatar_url" => nil,
              "community_roles" => [],
            },
            "blocked_user" => {
              "id" => alice.id,
              "display_name" => "John D.",
              "avatar_url" => nil,
              "community_roles" => [],
            },
          }
        }) }
      end

      context 'unique blocked_user_ids' do
        let(:params) { { blocked_user_ids: [alice.id] } }

        before { request }

        it { expect(response.status).to eq(201) }
        it { expect(result).to eq({
          "user_blocked_users" => [{
            "user" => {
              "id" => user.id,
              "display_name" => "John D.",
              "avatar_url" => nil,
              "community_roles" => [],
            },
            "blocked_user" => {
              "id" => alice.id,
              "display_name" => "John D.",
              "avatar_url" => nil,
              "community_roles" => [],
            },
          }]
        }) }
      end

      context 'multiple blocked_user_ids' do
        let(:params) { { blocked_user_ids: [alice.id, bob.id] } }

        before { request }

        it { expect(response.status).to eq(201) }
        it { expect(result).to eq({
          "user_blocked_users" => [{
            "user" => {
              "id" => user.id,
              "display_name" => "John D.",
              "avatar_url" => nil,
              "community_roles" => [],
            },
            "blocked_user" => {
              "id" => alice.id,
              "display_name" => "John D.",
              "avatar_url" => nil,
              "community_roles" => [],
            },
          }, {
            "user" => {
              "id" => user.id,
              "display_name" => "John D.",
              "avatar_url" => nil,
              "community_roles" => [],
            },
            "blocked_user" => {
              "id" => bob.id,
              "display_name" => "John D.",
              "avatar_url" => nil,
              "community_roles" => [],
            },
          }]
        }) }
      end

      context 'empty blocked_user_ids' do
        let(:params) { { blocked_user_ids: [] } }

        before { request }

        it { expect(response.status).to eq(201) }
        it { expect(result).to eq({
          "user_blocked_users" => []
        }) }
      end
    end
  end

  context 'destroy' do
    let!(:user_blocked_user_1) { create :user_blocked_user, user: user, blocked_user: alice }
    let!(:user_blocked_user_2) { create :user_blocked_user, user: user, blocked_user: bob }

    describe 'not authorized' do
      before { delete :destroy, params: { blocked_user_id: alice.id } }

      it { expect(response.status).to eq 401 }
      it { expect(user.blocked_user_ids).to match_array([alice.id, bob.id]) }
    end

    describe 'authorized' do
      let(:request) { delete :destroy, params: { token: user.token }.merge(params) }

      context 'using id' do
        let(:params) { { id: alice.id } }

        before { request }

        it { expect(response.status).to eq 200 }
        it { expect(user.blocked_user_ids).to match_array([bob.id]) }
      end

      context 'unique blocked_user_id' do
        let(:params) { { blocked_user_id: alice.id } }

        before { request }

        it { expect(response.status).to eq 200 }
        it { expect(user.blocked_user_ids).to match_array([bob.id]) }
      end

      context 'unique blocked_user_ids' do
        let(:params) { { blocked_user_ids: [alice.id] } }

        before { request }

        it { expect(response.status).to eq 200 }
        it { expect(user.blocked_user_ids).to match_array([bob.id]) }
      end

      context 'multiple blocked_user_ids' do
        let(:params) { { blocked_user_ids: [alice.id, bob.id] } }

        before { request }

        it { expect(response.status).to eq 200 }
        it { expect(user.blocked_user_ids).to match_array([]) }
      end

      context 'empty blocked_user_ids' do
        let(:params) { { blocked_user_ids: [] } }

        before { request }

        it { expect(response.status).to eq 200 }
        it { expect(user.blocked_user_ids).to match_array([alice.id, bob.id]) }
      end
    end
  end
end
