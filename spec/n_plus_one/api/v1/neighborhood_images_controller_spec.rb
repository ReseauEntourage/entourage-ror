require 'rails_helper'

describe Api::V1::NeighborhoodImagesController, type: :controller do
  let(:user) { create :public_user }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        count.times do
          path = "neighborhood_images/#{SecureRandom.hex(4)}.jpg"
          create :neighborhood_image, image_url: path
          create :image_resize_action, bucket: NeighborhoodImage::BUCKET_NAME, path: path, destination_path: "medium/#{path}", destination_size: :medium
        end
      end

      def perform_request
        get :index, params: { token: user.token }
      end

      def returned_items_count
        JSON.parse(response.body)['neighborhood_images'].size
      end
    end
  end
end
