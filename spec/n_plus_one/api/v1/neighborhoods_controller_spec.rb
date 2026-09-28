require 'rails_helper'

describe Api::V1::NeighborhoodsController, type: :controller do
  let(:user) do
    create(:pro_user).tap do |user|
      create :address, user: user, latitude: 48.86, longitude: 2.35, postal_code: '75020'
      user.reload
    end
  end

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        count.times do
          image_url = "neighborhood-#{SecureRandom.hex(4)}.jpg"
          member = create(:public_user)
          neighborhood = create :neighborhood,
            user: create(:public_user),
            participants: [member],
            interest_list: [:sport, :cuisine],
            image_url: image_url

          neighborhood.translation || create(:translation, instance: neighborhood, from_lang: :fr, en: { name: "#{neighborhood.name} (en)" })
          create :image_resize_action, bucket: NeighborhoodImage::BUCKET_NAME, path: image_url, destination_path: "medium/#{image_url}", destination_size: :medium
          create :outing, :outing_class, user: member, neighborhoods: [neighborhood]
          create :chat_message, messageable: neighborhood, user: neighborhood.user
        end
      end

      def perform_request
        get :index, params: { token: user.token }
      end

      def returned_items_count
        JSON.parse(response.body)['neighborhoods'].size
      end
    end
  end
end
