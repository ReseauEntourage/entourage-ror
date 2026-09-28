require 'rails_helper'
include AuthHelper

describe Admin::NewsletterSubscriptionsController, type: :controller do
  render_views

  let!(:user) { admin_basic_login }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        count.times { create :newsletter_subscription }
      end

      def perform_request
        get :index
      end

      def returned_items_count
        assigns(:newsletter_subscriptions).to_a.size
      end
    end
  end
end
