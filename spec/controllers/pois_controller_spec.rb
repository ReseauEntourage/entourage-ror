require 'rails_helper'

describe PoisController, :type => :controller do
  render_views
  
  context 'authorized' do
    let!(:user) { create :user }
    describe '#index' do
      context 'without parameters' do
        let!(:poi1) { create :poi, validated: true }
        let!(:poi2) { create :poi, validated: false }
        let!(:poi3) { create :poi, validated: true }
        let!(:category1) { create :category }
        let!(:category2) { create :category }
        before { get 'index', token: user.token, :format => :json }
        it { expect(assigns(:categories)).to eq([category1, category2]) }
        it { expect(assigns(:pois)).to eq([poi1, poi3]) }
      end
      context 'with location parameters' do
        let!(:poi1) { create :poi, latitude: 10, longitude: 12 }
        let!(:poi2) { create :poi, latitude: 9.9, longitude: 10.1 }
        let!(:poi3) { create :poi, latitude: 10, longitude: 10 }
        let!(:poi4) { create :poi, latitude: 10.05, longitude: 9.95 }
        let!(:poi5) { create :poi, latitude: 12, longitude: 10 }
        context 'without distance' do
          before { get :index, token: user.token, latitude: 10.0, longitude: 10.0, format: :json }
          it { should respond_with 200 }
          it { expect(assigns[:pois]).to eq [poi3, poi4] }
        end
        context 'with distance' do
          before { get :index, token: user.token, latitude: 10.0, longitude: 10.0, distance: 20.0, format: :json }
          it { should respond_with 200 }
          it { expect(assigns[:pois]).to eq [poi2, poi3, poi4] }
        end
      end
    end
  end
    
  context "unauthorized" do
    describe '#index' do
      before { get 'index', :format => :json }
      it { should respond_with 401 }
    end
  end
end
