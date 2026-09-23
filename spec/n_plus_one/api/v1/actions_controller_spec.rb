require 'rails_helper'

describe Api::V1::ActionsController, type: :controller do
  let(:user) { create :public_user }
  let(:latitude) { 48.85 }
  let(:longitude) { 2.27 }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries',
      pending: 'N+1 : image_resize_actions (V1::ActionSerializer#image_url -> Contribution.image_url_for_with_size -> ImageResizeAction.find_path_for, 1 requête par contribution avec image)' do
      def populate(count)
        count.times do
          [:contribution, :solicitation].each do |factory|
            action = create factory,
              user: create(:public_user, avatar_key: 'avatar'),
              latitude: latitude,
              longitude: longitude,
              section: :clothes,
              image_url: "#{SecureRandom.hex(4)}.jpg",
              participants: [create(:public_user)]

            create :translation, instance: action, from_lang: :fr,
              en: { 'title' => 'title en', 'description' => 'description en' }
          end
        end
      end

      def perform_request
        get :index, params: { token: user.token, latitude: latitude, longitude: longitude, per: 50 }
      end

      def returned_items_count
        JSON.parse(response.body)['actions'].size
      end
    end
  end
end
