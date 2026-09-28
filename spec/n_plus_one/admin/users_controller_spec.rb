require 'rails_helper'
include AuthHelper

describe Admin::UsersController, type: :controller do
  render_views

  let!(:user) { admin_basic_login }

  describe 'GET index' do
    context 'all users' do
      it_behaves_like 'an endpoint without N+1 queries' do
        def populate(count)
          count.times do |i|
            listed = create :public_user, goal: :offer_help, targeting_profile: :asks_for_help
            create :address, user: listed, postal_code: "750#{10 + i}"
          end
        end

        def perform_request
          get :index
        end

        def returned_items_count
          assigns(:users).to_a.size
        end
      end
    end

    context 'pending phone change requests' do
      it_behaves_like 'an endpoint without N+1 queries' do
        def populate(count)
          count.times do
            listed = create :public_user
            create :address, user: listed
            create :user_phone_change_request, user: listed, admin: user
          end
        end

        def perform_request
          get :index, params: { status: :pending }
        end

        def returned_items_count
          assigns(:users).to_a.size
        end
      end
    end
  end
end
