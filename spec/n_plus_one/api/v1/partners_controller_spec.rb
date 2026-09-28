require 'rails_helper'

describe Api::V1::PartnersController, type: :controller do
  let(:user) do
    create(:pro_user, travel_distance: 1000).tap do |user|
      create :address, user: user, latitude: 48.86, longitude: 2.35, postal_code: '75020'
      user.reload
    end
  end

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        count.times do
          partner = create :partner, name: "Partner #{SecureRandom.hex(4)}", latitude: 48.86, longitude: 2.35,
            postal_code: '75020', image_url: "logo-#{SecureRandom.hex(4)}.png"

          create :public_user, partner: partner
          create :following, user: create(:public_user), partner: partner
        end
      end

      def perform_request
        get :index, params: { token: user.token }
      end

      def returned_items_count
        JSON.parse(response.body)['partners'].size
      end
    end
  end
end
