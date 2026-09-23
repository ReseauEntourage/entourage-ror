require 'rails_helper'
include AuthHelper

describe Admin::UserMessageBroadcastsController, type: :controller do
  render_views

  let!(:user) { admin_basic_login }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        count.times do |i|
          create :user_message_broadcast, areas: ['75', '92'], goal: i.even? ? 'ask_for_help' : 'offer_help', sent_recipients_count: 3
        end
      end

      def perform_request
        get :index
      end

      def returned_items_count
        assigns(:user_message_broadcasts).to_a.size
      end
    end
  end
end
