require 'rails_helper'

describe Api::V1::AnnouncementsController, type: :controller do
  let(:user) { create :public_user }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        count.times do
          @position = (@position || 0) + 1
          create :announcement,
            id: nil,
            position: @position,
            areas: ['sans_zone', 'hors_zone'],
            user_goals: ['goal_not_known', 'offer_help', 'ask_for_help'],
            image_portrait_url: 'portrait.jpg'
        end
      end

      def perform_request
        get :index, params: { token: user.token }
      end

      def returned_items_count
        JSON.parse(response.body)['announcements'].size
      end
    end
  end
end
