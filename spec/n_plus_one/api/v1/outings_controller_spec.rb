require 'rails_helper'

describe Api::V1::OutingsController, type: :controller do
  let(:user) { create :public_user }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        count.times do
          create :outing, :outing_class, user: create(:public_user), participants: [create(:public_user)], interest_list: [:sport]
        end
      end

      def perform_request
        get :index, params: { token: user.token }
      end

      def returned_items_count
        JSON.parse(response.body)['outings'].size
      end
    end
  end
end
