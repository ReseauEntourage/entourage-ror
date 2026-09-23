require 'rails_helper'

describe Api::V1::MapController, type: :controller do
  let(:user) { create :pro_user }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        # chaque POI a sa propre catégorie (V1::PoiSerializer has_one :category en version :v1_list)
        count.times { create :poi, category: create(:category) }
      end

      def perform_request
        get :index, params: { token: user.token }
      end

      def returned_items_count
        JSON.parse(response.body)['pois'].size
      end
    end
  end
end
