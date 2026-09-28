require 'rails_helper'

describe Api::V1::EntourageImagesController, type: :controller do
  let(:user) { create :public_user }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        count.times do
          key = SecureRandom.hex(6)
          image = create :entourage_image, landscape_url: "landscape/#{key}", portrait_url: "portrait/#{key}"

          # versions redimensionnées (associations has_one :landscape_url_medium / :portrait_url_medium)
          [image[:landscape_url], image[:portrait_url]].each do |path|
            create :image_resize_action, bucket: EntourageImage::BUCKET_NAME, path: path, destination_path: "#{path}/medium"
          end
        end
      end

      def perform_request
        get :index, params: { token: user.token }
      end

      def returned_items_count
        JSON.parse(response.body)['entourage_images'].size
      end
    end
  end
end
