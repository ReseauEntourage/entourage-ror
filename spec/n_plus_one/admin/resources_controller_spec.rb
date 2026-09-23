require 'rails_helper'
include AuthHelper

describe Admin::ResourcesController, type: :controller do
  render_views

  let!(:user) { admin_basic_login }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries', pending: 'N+1 : COUNT des vues par ressource (views_for => resource.users.where(admin: false).count, resources_helper.rb:25)' do
      def populate(count)
        count.times do
          resource = create :resource, tag: :neighborhood
          create :translation, instance: resource, en: { name: 'How to help' }
          create :users_resource, resource: resource, user: create(:public_user), watched: true
        end
      end

      def perform_request
        get :index
      end

      def returned_items_count
        assigns(:resources).to_a.size
      end
    end
  end
end
