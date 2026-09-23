require 'rails_helper'
include AuthHelper

describe Admin::OutingsController, type: :controller do
  render_views

  let!(:user) { admin_basic_login }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        count.times do
          outing = create :outing, :outing_class,
            user: create(:public_user),
            participants: [create(:public_user)],
            interest_list: [:sport]

          create :entourage_moderation, :moderated, entourage: outing, moderator: create(:pro_user, admin: true)
        end
      end

      def perform_request
        get :index
      end

      def returned_items_count
        assigns(:outings).to_a.size
      end
    end
  end
end
