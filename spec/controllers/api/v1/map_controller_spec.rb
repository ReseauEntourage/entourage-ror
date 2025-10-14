require 'rails_helper'

RSpec.describe Api::V1::MapController, type: :controller do
  render_views

  let!(:user) { FactoryBot.create :pro_user }

  describe 'GET index' do
    context 'Access control' do
      it 'returns http success if user is logged in' do
        get 'index', params: { token: user.token, format: :json }
        expect(response.status).to eq(200)
      end
      it 'returns an error if user is not logged in' do
        get 'index', format: :json
        expect(response.status).to eq(401)
      end
    end

    context 'view scope variable assignment' do
      let!(:poi) { FactoryBot.create :poi }
      before { get 'index', params: { token: user.token, format: :json } }
      it 'assigns @categories' do
        expect(assigns(:categories)).to eq([poi.category])
      end
      it 'assigns @pois' do
        expect(assigns(:pois)).to eq([poi])
      end

      it 'renders pois' do
        res = JSON.parse(response.body)
        expect(res).to eq({'categories'=>[{'id'=>poi.category.id, 'name'=>poi.category.name}], 'pois'=>[{'id'=>poi.id, 'name'=>'Dede', 'description'=>nil, 'longitude'=>2.30681949999996, 'latitude'=>48.870424, 'adress'=>'Au 50 75008 Paris', 'phone'=>'0000000000', 'website'=>'entourage.com', 'email'=>'entourage@entourage.com', 'audience'=>'Mon audience', 'validated'=>true, 'category_id'=>poi.category.id, 'category'=>{'id'=>poi.category.id, 'name'=>poi.category.name}, 'partner_id'=>nil}]})
      end
    end

    context 'returned values limitations' do
      let!(:poi1) { FactoryBot.create :poi }
      let!(:poi2) { FactoryBot.create :poi }
      let!(:category) { FactoryBot.create :category }
      it 'returns all pois' do
        get 'index', params: { token: user.token, format: :json }
        expect(assigns(:pois)).to eq([poi1, poi2])
      end
      it 'returns only one poi' do
        get 'index', params: { token: user.token, limit: 1, format: :json }
        expect(assigns(:pois)).to eq([poi1])
      end
    end

    context 'returned geolocated pois' do
      let!(:poi1) { FactoryBot.create(:poi, latitude: 48.7, longitude: 2.3) }
      let!(:poi2) { FactoryBot.create(:poi, latitude: 48.8, longitude: 2.4) }
      let!(:poi3) { FactoryBot.create(:poi, latitude: 48.9, longitude: 2.5) }
      let!(:category) { FactoryBot.create :category }
      it 'returns all pois if no coordinates provided' do
        get 'index', params: { token: user.token, format: :json }
        expect(assigns(:pois)).to eq([poi1, poi2, poi3])
      end
      it 'returns 1 poi if coordinates provided and 1 km distance' do
        get 'index', params: { token: user.token, latitude: 48.7, longitude: 2.3, distance: 1, format: :json }
        expect(assigns(:pois)).to eq([poi1])
      end
      it 'returns 2 pois if coordinates provided and 15 km distance' do
        get 'index', params: { token: user.token, latitude: 48.7, longitude: 2.3, distance: 15, format: :json }
        expect(assigns(:pois)).to eq([poi1, poi2])
      end
      it 'returns 3 pois if coordinates provided and 30 km distance' do
        get 'index', params: { token: user.token, latitude: 48.7, longitude: 2.3, distance: 30, format: :json }
        expect(assigns(:pois)).to eq([poi1, poi2, poi3])
      end
    end

  end

end
