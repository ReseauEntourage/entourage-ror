require 'rails_helper'

describe Api::V1::UserBlockedUsersController, :type => :controller do
  render_views

  let(:user) { create :pro_user }
  let(:other) { create :pro_user }

  let(:result) { JSON.parse(response.body) }

  context 'create' do
    describe 'not authorized' do
      before { post :create }

      it { expect(response.status).to eq 401 }
    end

    describe 'authorized' do
      before { post :create, params: { token: user.token, user_blocked_user: { blocked_user_id: other.id }, format: :json } }

      it { expect(response.status).to eq(201) }
      it { expect(result).to eq({
        "user_blocked_user" => {
          "user" => {
            "id" => user.id,
            "display_name" => "John D.",
            "avatar_url" => nil
          },
          "blocked_user" => {
            "id" => other.id,
            "display_name" => "John D.",
            "avatar_url" => nil
          },
          "status" => "blocked"
        }
      }) }
    end
  end

  context 'destroy' do
    let!(:user_blocked_user) { create :user_blocked_user, user: user, blocked_user: other }

    describe 'not authorized' do
      before { delete :destroy, params: { id: other.id } }

      it { expect(response.status).to eq 401 }
      it { expect(user_blocked_user.reload.status).to eq 'blocked' }
    end

    describe 'authorized' do
      before { delete :destroy, params: { id: other.id, token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(user_blocked_user.reload.status).to eq 'not_blocked' }
    end
  end
end
