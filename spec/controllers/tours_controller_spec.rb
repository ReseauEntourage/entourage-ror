require 'rails_helper'

RSpec.describe ToursController, :type => :controller do
  render_views

  describe "POST create" do
    let!(:user) { FactoryGirl.create :user }
    let!(:tour) { FactoryGirl.build :tour }
    
    context "with correct type" do
      before { post 'create', token: user.token , tour: {tour_type: tour.tour_type, status:tour.status, vehicle_type:tour.vehicle_type}, :format => :json }

      it { should respond_with 201 }
      it { expect(assigns(:tour)).to eq(Tour.last) }
      it { expect(Tour.last.tour_type).to eq(tour.tour_type) }
      it { expect(Tour.last.status).to eq(tour.status) }
      it { expect(Tour.last.vehicle_type).to eq(tour.vehicle_type) }
      it { expect(Tour.last.user).to eq(user) }
    end

    context "with incorrect type" do
      before { post 'create', token: user.token , tour: {tour_type: 'invalid', status:tour.status, vehicle_type:tour.vehicle_type}, :format => :json }
      it { should respond_with 400 }
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
    
    let!(:user) { FactoryGirl.create :user }
    let!(:other_user) { FactoryGirl.create :user }
    let(:tour) { FactoryGirl.create(:tour, user: user) }
      
    context "with correct id" do
      before { put 'update', id: tour.id, token: user.token, tour:{tour_type:"health", status:"ongoing", vehicle_type:"car"}, format: :json }

      it { should respond_with 200 }
      it { expect(tour.reload.status).to eq("ongoing") }
      it { expect(tour.reload.vehicle_type).to eq("car") }
      it { expect(tour.reload.tour_type).to eq("health") }
    end

    context "close tour" do
      context "tour open" do
        let(:open_tour) { FactoryGirl.create(:tour, user: user, status: :ongoing) }
        before { put 'update', id: open_tour.id, token: user.token, tour:{tour_type:"health", status:"closed", vehicle_type:"car"}, format: :json }
        it { expect(open_tour.reload.closed?).to be true }
        it { expect(ActionMailer::Base.deliveries.last.to).to eq([user.email])}
      end

      context "tour closed" do
        let(:closed_tour) { FactoryGirl.create(:tour, user: user, status: :closed) }
        before { put 'update', id: closed_tour.id, token: user.token, tour:{tour_type:"health", status:"closed", vehicle_type:"car"}, format: :json }
        it { expect(closed_tour.reload.closed?).to be true }
        it { expect(ActionMailer::Base.deliveries.last).to be nil}
      end


    end

    context "with unexisting id" do
      before { put 'update', id: 0, token: user.token, tour:{tour_type:"health", status:"ongoing", vehicle_type:"car"}, format: :json }
      it { should respond_with 404 }
    end
    
    context "with incorrect_user" do
      before { put 'update', id: tour.id, token: other_user.token, tour:{tour_type:"health", status:"ongoing", vehicle_type:"car"}, format: :json }
      it { should respond_with 403 }
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
    
    context "with location parameter" do 
     
      let!(:tour1) { FactoryGirl.create :tour }
      let!(:tour_point1) { FactoryGirl.create :tour_point, tour: tour1, latitude: 10, longitude: 12 }
      let!(:tour2) { FactoryGirl.create :tour }
      let!(:tour_point2) { FactoryGirl.create :tour_point, tour: tour2, latitude: 9.9, longitude: 10.1 }
      let!(:tour3) { FactoryGirl.create :tour }
      let!(:tour_point3) { FactoryGirl.create :tour_point, tour: tour3, latitude: 10, longitude: 10 }
      let!(:tour4) { FactoryGirl.create :tour }
      let!(:tour_point4) { FactoryGirl.create :tour_point, tour: tour4, latitude: 10.05, longitude: 9.95 }
      let!(:tour5) { FactoryGirl.create :tour }
      let!(:tour_point5) { FactoryGirl.create :tour_point, tour: tour5, latitude: 12, longitude: 10 }
         
      it "returns status 200" do
        get 'index', token: user.token, latitude: 10.0, longitude: 10.0, :format => :json
        expect(response.status).to eq 200
      end
      
      it "returns only matching location tours" do
        get 'index', token: user.token, latitude: 10.0, longitude: 10.0, :format => :json
        expect(assigns(:tours)).to eq([tour4, tour3])
      end
      
      it "returns only matching location tours with provided distance" do
        get 'index', token: user.token, latitude: 10.0, longitude: 10.0, distance: 20.0, :format => :json
        expect(assigns(:tours)).to eq([tour4, tour3, tour2])
      end
       
    end
    
  end
end
