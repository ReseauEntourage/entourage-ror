require 'rails_helper'

describe Api::V1::UserBlockedUsersController, type: :controller do
  let(:user) { create :public_user }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        count.times do
          create :user_blocked_user, user: user, blocked_user: create(:public_user, avatar_key: "avatar_#{SecureRandom.hex(4)}")
        end
      end

      def perform_request
        get :index, params: { token: user.token }
      end

      def returned_items_count
        JSON.parse(response.body)['user_blocked_users'].size
      end
    end
  end
end
