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
      it "assigns tour" do
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

  describe "GET show" do
    
    context "with correct id" do

      let!(:user) { FactoryGirl.create :user }
      let!(:tour) { FactoryGirl.create :tour }

      it "returns 200" do
        get 'show', id: tour.id, token: user.token , :format => :json
        expect(response.status).to eq(200)
      end
      it "assigns tour" do
        get 'show', id: tour.id, token: user.token , :format => :json
        expect(assigns(:tour)).to eq(tour)
      end
    end

    context "with unexisting id" do
      let!(:user) { FactoryGirl.create :user }
      let!(:tour) { FactoryGirl.build(:tour, tour_type:"invalid") }

      it "retours error 404" do
        get 'show', id: 0, token: user.token , :format => :json
        expect(response.status).to eq(404)
      end

    end

  end
end
