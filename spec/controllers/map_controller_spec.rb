require 'rails_helper'

RSpec.describe MapController, :type => :controller do

  describe "GET index" do
    context "returns" do
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

    context "assigns" do
      let!(:user) { FactoryGirl.create :user }
      let!(:poi) { FactoryGirl.create :poi }
      let!(:category) { FactoryGirl.create :category }
      let!(:encounter) { FactoryGirl.create :valid_encounter }
      before { get 'index', token: user.token, :format => :json }
      it "@categories" do
        expect(assigns(:categories)).to eq([category])
      end
      it "@pois" do
        expect(assigns(:pois)).to eq([poi])
      end
      it "@encounters" do
        expect(assigns(:encounters)).to eq([encounter])
      end
    end

  end

end
