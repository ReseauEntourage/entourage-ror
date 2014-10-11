require 'rspec/rails'
require 'rails_helper'
require 'spec_helper'

RSpec.describe PoisController, :type => :controller do

  let!(:poi) { FactoryGirl.create :poi }
  let!(:category) { FactoryGirl.create :category }

  describe "GET index" do

    it "assigns @categories" do
      get 'index', :format => :json
      expect(assigns(:categories)).to eq([category])
    end
    it "assigns @pois" do
      get 'index', :format => :json
      expect(assigns(:pois)).to eq([poi])
    end
  end
end
