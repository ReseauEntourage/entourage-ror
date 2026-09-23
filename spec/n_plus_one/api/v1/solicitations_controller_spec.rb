require 'rails_helper'

describe Api::V1::SolicitationsController, type: :controller do
  render_views

  let(:user) { create :pro_user, lang: 'en' }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        count.times do
          key = SecureRandom.hex(4)
          solicitation = create :solicitation,
            user: create(:public_user, avatar_key: 'avatar.jpg'),
            section: 'social',
            latitude: 48.85,
            longitude: 2.27,
            participants: [user, create(:public_user)],
            metadata: { landscape_url: "landscape-#{key}.jpg", portrait_url: "portrait-#{key}.jpg" }
          create :translation, instance: solicitation, en: { title: 'title en', description: 'description en' }
        end
      end

      def perform_request
        get :index, params: { token: user.token }
      end

      def returned_items_count
        JSON.parse(response.body)['solicitations'].size
      end
    end
  end
end
