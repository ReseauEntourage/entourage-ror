require 'rails_helper'
include AuthHelper

describe Admin::PoisController, type: :controller do
  render_views

  let!(:user) { admin_basic_login }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        # la factory crée une catégorie distincte pour chaque POI
        count.times { create :poi }
      end

      def perform_request
        get :index
      end

      def returned_items_count
        assigns(:pois).to_a.size
      end
    end
  end
end
