require 'rails_helper'

describe Api::V1::ResourcesController, type: :controller do
  render_views

  let(:user) { create :pro_user, lang: 'en' }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        count.times do
          resource = create :resource, description: '<p>description</p>', image_url: "resources/#{SecureRandom.hex(4)}.jpg", url: 'https://www.entourage.social'
          create :translation, instance: resource, en: { name: 'How to help', description: '<p>description en</p>' }
          create :users_resource, user: user, resource: resource, watched: true
          create :users_resource, user: create(:public_user), resource: resource, watched: true
        end
      end

      # sans nohtml : chaque ressource rend aussi son html (ResourceServices::Format)
      def perform_request
        get :index, params: { token: user.token }
      end

      def returned_items_count
        JSON.parse(response.body)['resources'].size
      end
    end
  end
end
