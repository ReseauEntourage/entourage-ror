require 'rails_helper'
include AuthHelper

describe Admin::OptionsController, type: :controller do
  render_views

  let!(:user) { super_admin_basic_login }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        count.times { create :option, key: "key_#{SecureRandom.hex(4)}", description: 'description' }
      end

      def perform_request
        get :index
      end

      def returned_items_count
        assigns(:options).to_a.size
      end
    end
  end
end
