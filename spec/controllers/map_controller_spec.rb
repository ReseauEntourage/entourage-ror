require 'rails_helper'

RSpec.describe MapController, :type => :controller do

  describe "GET index" do
    context "Access control" do
      let!(:user) { FactoryGirl.create :user }
      it "returns http success if user is logged in" do
        get 'index', token: user.token, :format => :json
        expect(response).to be_success
      end
      it "returns an error if user is not logged in" do
        get 'index', :format => :json
        expect(response).not_to be_success
      end
    end

    context "view scope variable assignment" do
      let!(:user) { FactoryGirl.create :user }
      let!(:poi) { FactoryGirl.create :poi }
      let!(:category) { FactoryGirl.create :category }
      let!(:encounter) { FactoryGirl.create :valid_encounter }
      before { get 'index', token: user.token, :format => :json }
      it "assigns @categories" do
        expect(assigns(:categories)).to eq([category])
      end
      it "assigns @pois" do
        expect(assigns(:pois)).to eq([poi])
      end
      it "assigns @encounters" do
        expect(assigns(:encounters)).to eq([encounter])
      end
    end

    context "returned values limitations" do
      let!(:poi1) { FactoryGirl.create :poi }
      let!(:poi2) { FactoryGirl.create :poi }
      let!(:category) { FactoryGirl.create :category }
      let!(:user) { create :user }
      it "returns all pois" do
        get 'index', token: user.token, :format => :json
        expect(assigns(:pois)).to eq([poi1, poi2])
      end
      it "returns only one poi" do
        get 'index', token: user.token, :limit => 1, :format => :json
        expect(assigns(:pois)).to eq([poi1])
      end
    end

  end

end
