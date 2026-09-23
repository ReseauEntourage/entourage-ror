require 'rails_helper'

describe Api::V1::PoisController, type: :controller do
  let(:user) { create :pro_user }

  def populate(count)
    count.times do
      poi = create :poi, category: create(:category)
      # une seconde catégorie distincte par POI (category_ids en v2)
      poi.categories << create(:category)
    end
  end

  # PoiOptimizedSerializer met en cache (redis) le JSON de chaque POI : sans purge, la
  # mesure "petit jeu" ne sérialiserait rien (tout en cache après la chauffe) et seuls les
  # POI ajoutés seraient sérialisés dans la mesure "grand jeu".
  def perform_request_with(version)
    PoiServices::PoiOptimizedSerializer.clear_cache
    get :index, params: { token: user.token, latitude: 48.870424, longitude: 2.30681949999996, distance: 1, v: version, format: :json }
  end

  def returned_items_count
    JSON.parse(response.body)['pois'].size
  end

  describe 'GET index' do
    context 'v1' do
      it_behaves_like 'an endpoint without N+1 queries' do
        def perform_request
          perform_request_with('1')
        end
      end
    end

    context 'v2' do
      it_behaves_like 'an endpoint without N+1 queries', pending: 'N+1 : categories_pois (V1::PoiSerializer#category_ids fait CategoryPoi.where(poi_id:) par POI, masqué seulement par le cache redis)' do
        def perform_request
          perform_request_with('2')
        end
      end
    end
  end
end
