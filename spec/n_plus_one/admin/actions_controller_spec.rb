require 'rails_helper'
include AuthHelper

describe Admin::ActionsController, type: :controller do
  render_views

  let!(:user) { admin_basic_login }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        count.times do |i|
          create :entourage, :moderation_moderated,
            user: create(:public_user),
            entourage_type: i.even? ? 'ask_for_help' : 'contribution',
            postal_code: '75001',
            participants: [create(:public_user)]
        end
      end

      def perform_request
        get :index
      end

      def returned_items_count
        assigns(:actions).to_a.size
      end
    end
  end
end
