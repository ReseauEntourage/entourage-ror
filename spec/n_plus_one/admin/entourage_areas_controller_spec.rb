require 'rails_helper'
include AuthHelper

describe Admin::EntourageAreasController, type: :controller do
  render_views

  let!(:user) { super_admin_basic_login }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        count.times do
          create :entourage_area, postal_code: format('%02d', EntourageArea.count + 10), display_name: "Zone #{EntourageArea.count}"
        end
      end

      def perform_request
        get :index
      end

      def returned_items_count
        assigns(:entourage_areas).to_a.size
      end
    end
  end
end
