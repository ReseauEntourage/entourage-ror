require 'rails_helper'

RSpec.describe PoisController, :type => :controller do

  let!(:poi) { FactoryGirl.create :poi }
  let!(:category) { FactoryGirl.create :category }

  describe "GET index" do
    before(:each)do
      get 'index', :format => :json
    end
    it "returns http success" do
      expect(response).to be_success
    end
    it "assigns @categories" do
      expect(assigns(:categories)).to eq([category])
    end
    it "assigns @pois" do
      expect(assigns(:pois)).to eq([poi])
    end
  end
end
