require 'rails_helper'
include AuthHelper

describe Admin::MessagesController, type: :controller do
  render_views

  let!(:user) { admin_basic_login }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        count.times do |i|
          Message.create!(first_name: "First #{i}", last_name: "Last #{i}", email: "message#{i}@mail.com", content: "Content #{i}")
        end
      end

      def perform_request
        get :index
      end

      def returned_items_count
        assigns(:messages).to_a.size
      end
    end
  end
end
