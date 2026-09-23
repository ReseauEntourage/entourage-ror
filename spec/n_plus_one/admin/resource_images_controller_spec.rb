require 'rails_helper'
include AuthHelper

describe Admin::ResourceImagesController, type: :controller do
  render_views

  let!(:user) { admin_basic_login }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        count.times do
          ResourceImage.create!(title: "photo #{SecureRandom.hex(4)}", image_url: "resource_images/#{SecureRandom.hex(4)}.jpg")
        end
      end

      def perform_request
        get :index
      end

      def returned_items_count
        assigns(:resource_images).to_a.size
      end
    end
  end
end
