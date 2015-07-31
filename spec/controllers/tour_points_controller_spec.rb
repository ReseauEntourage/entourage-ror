require 'rails_helper'

RSpec.describe TourPointsController, :type => :controller do
  
  describe "POST create" do
    
    context "within existing tour" do

      let!(:user) { FactoryGirl.create :user }
      let!(:tour) { FactoryGirl.create :tour }
      let!(:tour_point) { FactoryGirl.build :tour_point }

      it "returns 201" do
        post 'create', tour_id: tour.id, token: user.token , tour_points: [{latitude: tour_point.latitude, longitude: tour_point.longitude, passing_time: tour_point.passing_time}], :format => :json
        expect(response.status).to eq(201)
      end
      it "assigns tour" do
        post 'create', tour_id: tour.id, token: user.token , tour_points: [{latitude: tour_point.latitude, longitude: tour_point.longitude, passing_time: tour_point.passing_time}], :format => :json
        expect(assigns(:tour)).to eq(tour)
      end
      it "assigns tour_point" do
        post 'create', tour_id: tour.id, token: user.token , tour_points: [{latitude: tour_point.latitude, longitude: tour_point.longitude, passing_time: tour_point.passing_time}], :format => :json
        last_tour_point = TourPoint.last
        expect(assigns(:tour).tour_points).to eq([last_tour_point])
      end
    
      context "with multiple tour points" do
      
        let!(:user) { FactoryGirl.create :user }
        let!(:tour) { FactoryGirl.create :tour }
        let!(:tour_point) { FactoryGirl.build :tour_point }
        
        it "returns 201" do
          post 'create', tour_id: tour.id, token: user.token , tour_points: [{latitude: tour_point.latitude, longitude: tour_point.longitude, passing_time: tour_point.passing_time}, {latitude: tour_point.latitude, longitude: tour_point.longitude, passing_time: tour_point.passing_time}], :format => :json
          expect(response.status).to eq(201)
        end
        it "assigns tour" do
          post 'create', tour_id: tour.id, token: user.token , tour_points: [{latitude: tour_point.latitude, longitude: tour_point.longitude, passing_time: tour_point.passing_time}, {latitude: tour_point.latitude, longitude: tour_point.longitude, passing_time: tour_point.passing_time}], :format => :json
          expect(assigns(:tour)).to eq(tour)
        end
        it "assigns tour_points" do
          post 'create', tour_id: tour.id, token: user.token , tour_points: [{latitude: tour_point.latitude, longitude: tour_point.longitude, passing_time: tour_point.passing_time}, {latitude: tour_point.latitude, longitude: tour_point.longitude, passing_time: tour_point.passing_time}], :format => :json
          last_tour_points = TourPoint.last(2)
          expect(assigns(:tour).tour_points).to eq(last_tour_points)
        end
        
      end
      
    end

    context "with inexisting tour" do
      let!(:user) { FactoryGirl.create :user }
      let!(:tour_point) { FactoryGirl.build :tour_point }

      it "retours error 404" do
        post 'create', tour_id: 0, token: user.token , tour_points: [{latitude: tour_point.latitude, longitude: tour_point.longitude, passing_time: tour_point.passing_time}], :format => :json
        expect(response.status).to eq(404)
      end

    end

    context "with invalid tour_point" do
      let!(:user) { FactoryGirl.create :user }
      let!(:tour_point) { FactoryGirl.build :tour_point }
      let!(:tour) { FactoryGirl.create :tour }

      it "retours error 400" do
        post 'create', tour_id: tour.id, token: user.token , tour_points: [{latitude: "ABC", longitude: "DEF", passing_time: "GHI"}], :format => :json
        expect(response.status).to eq(400)
      end

    end

  end
end
