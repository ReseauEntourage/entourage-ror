require 'rails_helper'
include AuthHelper

describe Admin::NeighborhoodsController, type: :controller do
  render_views

  let!(:user) { admin_basic_login }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        count.times { create :neighborhood, user: create(:public_user), participants: [create(:public_user)] }
      end

      def perform_request
        get :index
      end

      def returned_items_count
        assigns(:neighborhoods).to_a.size
      end
    end
  end
end
