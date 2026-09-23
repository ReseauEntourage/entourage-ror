require 'rails_helper'

describe Api::V1::ContributionsController, type: :controller do
  let(:user) { create :public_user }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        count.times do
          contribution = create :contribution,
            user: create(:public_user, avatar_key: "avatar_#{SecureRandom.hex(4)}"),
            section: 'social',
            image_url: "contribution_#{SecureRandom.hex(4)}.jpg",
            participants: [create(:public_user), create(:public_user)]

          contribution.translation || create(:translation, instance: contribution)
        end
      end

      def perform_request
        get :index, params: { token: user.token, latitude: 1.122, longitude: 2.345, per: 50 }
      end

      def returned_items_count
        JSON.parse(response.body)['contributions'].size
      end
    end
  end
end
