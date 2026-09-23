require 'rails_helper'
include AuthHelper

describe Admin::NeighborhoodImagesController, type: :controller do
  render_views

  let!(:user) { admin_basic_login }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        count.times do
          path = "neighborhood_images/#{SecureRandom.hex(4)}.jpg"

          create :neighborhood_image, title: "Photo #{SecureRandom.hex(4)}", image_url: path
          create :image_resize_action, bucket: NeighborhoodImage::BUCKET_NAME, path: path, destination_path: "medium/#{path}", destination_size: :medium
        end
      end

      def perform_request
        get :index
      end

      def returned_items_count
        assigns(:neighborhood_images).to_a.size
      end
    end
  end
end
