require 'rails_helper'

RSpec.describe ToursController, :type => :controller do
  
  describe "POST create" do
    
    context "with correct type" do

      let!(:user) { FactoryGirl.create :user }
      let!(:tour) { FactoryGirl.build :tour }

      it "returns 201" do
        post 'create', token: user.token , tour: {tour_type: tour.tour_type, status:tour.status, vehicle_type:tour.vehicle_type}, :format => :json
        expect(response.status).to eq(201)
      end
      it "assigns tour" do
        post 'create', token: user.token , tour: {tour_type: tour.tour_type, status:tour.status, vehicle_type:tour.vehicle_type}, :format => :json
        last_tour = Tour.last
        expect(assigns(:tour)).to eq(last_tour)
      end
    end

    context "with incorrect type" do
      let!(:user) { FactoryGirl.create :user }
      let!(:tour) { FactoryGirl.build(:tour, tour_type:"invalid") }

      it "retours error 400" do
        post 'create', token: user.token , tour: {tour_type: tour.tour_type, status:tour.status, vehicle_type:tour.vehicle_type}, :format => :json
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

  describe "PUT update" do
    
    context "with correct id" do

      let!(:user) { FactoryGirl.create :user }
      let!(:tour) { FactoryGirl.create :tour }

      it "updates tour" do
        put 'update', id: tour.id, token: user.token, tour:{tour_type:tour.tour_type, status:"closed", vehicle_type:"car"}, format: :json
        expect(tour.reload.status).to eq("closed")
        expect(tour.reload.vehicle_type).to eq("car")
      end

    end

    context "with unexisting id" do
      let!(:user) { FactoryGirl.create :user }
      let!(:tour) { FactoryGirl.build(:tour, tour_type:"invalid") }

      it "retours error 404" do
        put 'update', id: 0, token: user.token , :format => :json
        expect(response.status).to eq(404)
      end

    end

  end
  
  describe "GET index" do
    
    let!(:user) { FactoryGirl.create :user }
    
    context "without parameter" do
    
      let!(:tour1) { FactoryGirl.create :tour, updated_at:0 }
      let!(:tour2) { FactoryGirl.create :tour, updated_at:1 }
      let!(:tour3) { FactoryGirl.create :tour, updated_at:2 }
      let!(:tour4) { FactoryGirl.create :tour, updated_at:3 }
      let!(:tour5) { FactoryGirl.create :tour, updated_at:4 }
      let!(:tour6) { FactoryGirl.create :tour, updated_at:5 }
      let!(:tour7) { FactoryGirl.create :tour, updated_at:6 }
      let!(:tour8) { FactoryGirl.create :tour, updated_at:7 }
      let!(:tour9) { FactoryGirl.create :tour, updated_at:8 }
      let!(:tour10) { FactoryGirl.create :tour, updated_at:9 }
      let!(:tour11) { FactoryGirl.create :tour, updated_at:10 }
         
      it "returns status 200" do
        get 'index', token: user.token, :format => :json
        expect(response.status).to eq 200
      end
      
      it "returns last 10 tours" do
        get 'index', token: user.token, :format => :json
        expect(assigns(:tours)).to eq([tour11, tour10, tour9, tour8, tour7, tour6, tour5, tour4, tour3, tour2])
      end
      
    end
     
    context "with limit parameter" do
     
      let!(:tour1) { FactoryGirl.create :tour, updated_at:0 }
      let!(:tour2) { FactoryGirl.create :tour, updated_at:1 }
      let!(:tour3) { FactoryGirl.create :tour, updated_at:2 }
      let!(:tour4) { FactoryGirl.create :tour, updated_at:3 }
      let!(:tour5) { FactoryGirl.create :tour, updated_at:4 }
         
      it "returns status 200" do
        get 'index', token: user.token, limit: 3, :format => :json
        expect(response.status).to eq 200
      end
      
      it "returns last 3 tours" do
        get 'index', token: user.token, limit: 3, :format => :json
        expect(assigns(:tours)).to eq([tour5, tour4, tour3])
      end
       
    end
     
    context "with type parameter" do 
     
      let!(:tour1) { FactoryGirl.create :tour, tour_type:'other' }
      let!(:tour2) { FactoryGirl.create :tour, tour_type:'other' }
      let!(:tour3) { FactoryGirl.create :tour, tour_type:'friendly' }
      let!(:tour4) { FactoryGirl.create :tour, tour_type:'friendly' }
      let!(:tour5) { FactoryGirl.create :tour, tour_type:'other' }
         
      it "returns status 200" do
        get 'index', token: user.token, type:'friendly', :format => :json
        expect(response.status).to eq 200
      end
      
      it "returns only matching type tours" do
        get 'index', token: user.token, type:'friendly', :format => :json
        expect(assigns(:tours)).to eq([tour4, tour3])
      end
       
    end
    
    context "with vehicle type parameter" do 
     
      let!(:tour1) { FactoryGirl.create :tour, vehicle_type:'feet' }
      let!(:tour2) { FactoryGirl.create :tour, vehicle_type:'feet' }
      let!(:tour3) { FactoryGirl.create :tour, vehicle_type:'car' }
      let!(:tour4) { FactoryGirl.create :tour, vehicle_type:'car' }
      let!(:tour5) { FactoryGirl.create :tour, vehicle_type:'feet' }
         
      it "returns status 200" do
        get 'index', token: user.token, vehicle_type:'car', :format => :json
        expect(response.status).to eq 200
      end
      
      it "returns only matching vehicle type tours" do
        get 'index', token: user.token, vehicle_type:'car', :format => :json
        expect(assigns(:tours)).to eq([tour4, tour3])
      end
       
    end
    
  end
  
end
