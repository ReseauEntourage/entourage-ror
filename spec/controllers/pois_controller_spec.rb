require 'rails_helper'

describe PoisController, :type => :controller do
  render_views
  
  context 'authorized' do
    let!(:user) { create :user }
    describe '#index' do
      let!(:poi1) { create :poi, validated: true }
      let!(:poi2) { create :poi, validated: false }
      let!(:poi3) { create :poi, validated: true }
      let!(:category1) { create :category }
      let!(:category2) { create :category }
      before { get 'index', token: user.token, :format => :json }
      it { expect(assigns(:categories)).to eq([category1, category2]) }
      it { expect(assigns(:pois)).to eq([poi1, poi3]) }
    end
  end
    
  context "unauthorized" do
    describe '#index' do
      before { get 'index', :format => :json }
      it { should respond_with 401 }
    end
  end
end
