require 'rails_helper'
include AuthHelper

describe Admin::EntourageImagesController, type: :controller do
  render_views

  let!(:user) { super_admin_basic_login }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        count.times do |i|
          landscape = "entourage_images/images/landscape-#{SecureRandom.hex(4)}.jpg"
          portrait = "entourage_images/images/portrait-#{SecureRandom.hex(4)}.jpg"

          create :entourage_image, title: "Photo #{SecureRandom.hex(4)}", landscape_url: landscape, portrait_url: portrait

          # versions redimensionnées affichées par la vue (landscape/portrait_url_medium_or_default)
          create :image_resize_action, bucket: EntourageImage::BUCKET_NAME, path: landscape, destination_path: "#{landscape}-medium", destination_size: :medium
          create :image_resize_action, bucket: EntourageImage::BUCKET_NAME, path: portrait, destination_path: "#{portrait}-medium", destination_size: :medium
        end
      end

      def perform_request
        get :index
      end

      def returned_items_count
        assigns(:entourage_images).to_a.size
      end
    end
  end
end
