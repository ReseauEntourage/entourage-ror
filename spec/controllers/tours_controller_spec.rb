require 'rails_helper'

RSpec.describe ToursController, :type => :controller do
  
  describe "POST create" do
    
    context "with correct type" do

      let!(:user) { FactoryGirl.create :user }
      let!(:tour) { FactoryGirl.build :tour }

      it "returns 201" do
        post 'create', token: user.token , tour: {tour_type: tour.tour_type}, :format => :json
        expect(response.status).to eq(201)
      end
      it "returns serialized tour" do
        post 'create', token: user.token , tour: {tour_type: tour.tour_type}, :format => :json
        last_tour = Tour.last
        expect(assigns(:tour)).to eq(last_tour)
      end
    end

    context "with incorrect type" do
      let!(:user) { FactoryGirl.create :user }
      let!(:tour) { FactoryGirl.build(:tour, tour_type:"invalid") }

      it "retours error 400" do
        post 'create', token: user.token , tour: {tour_type: tour.tour_type}, :format => :json
        expect(response.status).to eq(400)
      end

    end

  end

end
