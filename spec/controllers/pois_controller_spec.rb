require 'rails_helper'

RSpec.describe PoisController, :type => :controller do

  describe "GET index" do
    
    context "Access control" do
      let!(:user) { FactoryGirl.create :user }
      it "http success if user is logged in" do
        get 'index', token: user.token, :format => :json
        expect(response).to be_success
      end
      it "an error if user is not logged in" do
        get 'index', :format => :json
        expect(response).not_to be_success
      end
    end

    context "view scope variable assignment" do
      let!(:poi) { FactoryGirl.create :poi }
      let!(:category) { FactoryGirl.create :category }
      let!(:user) { create :user }
      before { get 'index', token: user.token, :format => :json }
      it "assigns @categories" do
        expect(assigns(:categories)).to eq([category])
      end
      it "assigns @pois" do
        expect(assigns(:pois)).to eq([poi])
      end
    end

  end
end