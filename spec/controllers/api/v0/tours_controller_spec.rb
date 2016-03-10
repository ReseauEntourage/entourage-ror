require 'rails_helper'

RSpec.describe Api::V0::ToursController, :type => :controller do
  render_views

  let!(:user) { FactoryGirl.create :pro_user }

  describe "POST create" do
    let!(:tour) { FactoryGirl.build :tour }
    
    context "with correct type" do
      before { FactoryGirl.create(:android_app) }
      before { post 'create', token: user.token , tour: {tour_type: tour.tour_type, status:tour.status, vehicle_type:tour.vehicle_type, distance: 123.456}, format: :json }

      it { expect(response.status).to eq(201) }
      it { expect(Tour.last.tour_type).to eq(tour.tour_type) }
      it { expect(Tour.last.status).to eq(tour.status) }
      it { expect(Tour.last.vehicle_type).to eq(tour.vehicle_type) }
      it { expect(Tour.last.user).to eq(user) }
      it { expect(Tour.last.members).to eq([user]) }
      it { expect(ToursUser.last.status).to eq("accepted") }

      it "responds with tour" do
        res = JSON.parse(response.body)
        last_tour = Tour.last
        expect(res).to eq({"tour"=>{"id"=>last_tour.id, "tour_type"=>"medical", "status"=>"ongoing", "vehicle_type"=>"feet", "distance"=>123, "organization_name"=>last_tour.user.organization.name, "organization_description"=>"Association description", "start_time"=>nil, "end_time"=>nil, "user_id"=>user.id, "tour_points"=>[]}})
      end
    end

    it "sends scheduled push" do
      FactoryGirl.create(:android_app)
      expect_any_instance_of(TourServices::SchedulePushService).to receive(:send_to)
      post 'create', token: user.token , tour: {tour_type: tour.tour_type, status:tour.status, vehicle_type:tour.vehicle_type, distance: 123.456}, format: :json
    end

    context "with incorrect type" do
      before { post 'create', token: user.token , tour: {tour_type: 'invalid', status:tour.status, vehicle_type:tour.vehicle_type, distance: 123.456}, :format => :json }
      it { expect(response.status).to eq(400) }
    end
  end

  describe "GET show" do
    before { Timecop.freeze(Time.parse("10/10/2010").at_beginning_of_day) }

    context "with correct id" do
      let!(:tour) { FactoryGirl.create :tour, :filled }
      before { get 'show', id: tour.id, token: user.token , format: :json }
      it { expect(response.status).to eq(200) }

      it "responds with tour" do
        res = JSON.parse(response.body)
        start_time = tour.tour_points.first.passing_time.iso8601(3)
        end_time = tour.tour_points.last.passing_time.iso8601(3)
        last_tour = Tour.last
        expect(res).to eq({"tour"=>{"id"=>last_tour.id,
                                    "tour_type"=>"medical",
                                    "status"=>"closed",
                                    "vehicle_type"=>"feet",
                                    "distance"=>tour.length,
                                    "organization_name"=>last_tour.user.organization.name,
                                    "organization_description"=>"Association description",
                                    "start_time"=>start_time,
                                    "end_time"=>end_time,
                                    "user_id"=>last_tour.user_id,
                                    "tour_points"=>[{"latitude"=>48.83, "longitude"=>2.29, "passing_time"=>tour.tour_points.first.passing_time.iso8601(3)}, {"latitude"=>48.83, "longitude"=>2.29, "passing_time"=>tour.tour_points.last.passing_time.iso8601(3)}]}})
      end
    end

    context "with unexisting id" do
      it "returns error 404" do
        expect {
          get 'show', id: 0, token: user.token , format: :json
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "has simplified tour points" do
      let!(:tour) { FactoryGirl.create(:tour)}
      let!(:tour_points) { FactoryGirl.create_list(:tour_point, 2, tour: tour)}
      let!(:simplified_tour_points) { FactoryGirl.create(:simplified_tour_point, tour: tour)}
      before { get 'show', id: tour.id, token: user.token , format: :json }
      it { expect(JSON.parse(response.body)["tour"]["tour_points"].count).to eq(1) }
    end

    context "don't have simplified tour points" do
      let!(:tour) { FactoryGirl.create(:tour)}
      let!(:tour_points) { FactoryGirl.create_list(:tour_point, 2, tour: tour)}
      before { get 'show', id: tour.id, token: user.token , format: :json }
      it { expect(JSON.parse(response.body)["tour"]["tour_points"].count).to eq(2) }
    end
  end

  describe "PUT update" do
    before { Timecop.freeze(DateTime.parse("10/10/2010").at_beginning_of_day) }
    let!(:other_user) { FactoryGirl.create :pro_user }
    let(:tour) { FactoryGirl.create(:tour, :filled, user: user) }
      
    context "with correct id" do
      before { put 'update', id: tour.id, token: user.token, tour:{tour_type:"medical", status:"closed", vehicle_type:"car", distance: 123.456}, format: :json }

      it { expect(response.status).to eq(200) }
      it { expect(tour.reload.status).to eq("closed") }
      it { expect(tour.reload.vehicle_type).to eq("car") }
      it { expect(tour.reload.tour_type).to eq("medical") }

      it "responds with tour" do
        res = JSON.parse(response.body)
        start_time = tour.tour_points.first.passing_time.iso8601(3)
        end_time = tour.tour_points.last.passing_time.iso8601(3)
        expect(res).to eq({"tour"=>{"id"=>tour.id, 
                                    "tour_type"=>"medical",
                                    "status"=>"closed",
                                    "vehicle_type"=>"car",
                                    "distance"=>tour.length,
                                    "organization_name"=>tour.user.organization.name,
                                    "organization_description"=>"Association description",
                                    "start_time"=>start_time,
                                    "end_time"=>end_time,
                                    "user_id"=>tour.user_id,
                                    "tour_points"=>[{"latitude"=>48.83, "longitude"=>2.29, "passing_time"=>tour.tour_points.first.passing_time.iso8601(3)}, {"latitude"=>48.83, "longitude"=>2.29, "passing_time"=>tour.tour_points.last.passing_time.iso8601(3)}]}})
      end
    end

    context "close tour" do
      context "tour open" do
        let(:open_tour) { FactoryGirl.create(:tour, user: user, status: :ongoing) }
        before { put 'update', id: open_tour.id, token: user.token, tour:{tour_type:"medical", status:"closed", vehicle_type:"car", distance: 633.0878}, format: :json }
        it "somthe" do
          expect(open_tour.reload.closed?).to be true
        end
        it { expect(ActionMailer::Base.deliveries.last.to).to eq([user.email])}
        it { expect(open_tour.reload.length).to eq(633)}
      end

      context "tour closed" do
        let(:closed_tour) { FactoryGirl.create(:tour, user: user, status: :closed) }
        before { put 'update', id: closed_tour.id, token: user.token, tour:{tour_type:"medical", status:"closed", vehicle_type:"car", distance: 123.456}, format: :json }
        it { expect(closed_tour.reload.closed?).to be true }
        it { expect(ActionMailer::Base.deliveries.last).to be nil}
      end


    end

    context "with unexisting id" do
      it { expect {
            put 'update', id: 0, token: user.token, tour:{tour_type:"medical", status:"ongoing", vehicle_type:"car", distance: 123.456}, format: :json
          }.to raise_error(ActiveRecord::RecordNotFound)
        }
    end
    
    context "with incorrect_user" do
      before { put 'update', id: tour.id, token: other_user.token, tour:{tour_type:"medical", status:"ongoing", vehicle_type:"car", distance: 123.456}, format: :json }
      it { expect(response.status).to eq(403) }
    end

  end
  
  describe "GET index" do
    let(:date) { Date.parse("10/10/2010") }
    before { Timecop.freeze(Time.parse("10/10/2010").at_beginning_of_day) }

    context "without parameter" do
      before(:each) do
        11.times do |i|
          FactoryGirl.create :tour, updated_at:date+i.hours
        end
      end

      before { get 'index', token: user.token, format: :json }
         
      it { expect(response.status).to eq 200 }
      it { expect(assigns(:tours).count).to eq(10) }
      it { expect(assigns(:tours).all? {|t| t.updated_at >= Date.parse("10/10/2010").at_beginning_of_day }).to be true }
    end

    it "responds with tours" do
      Timecop.freeze(DateTime.parse("10/10/2010").at_beginning_of_day)
      tours = FactoryGirl.create_list :tour, 2

      get 'index', token: user.token, format: :json

      res = JSON.parse(response.body)
      expect(res).to eq({"tours"=>[
          {"id"=>tours.first.id,
           "tour_type"=>"medical",
           "status"=>"ongoing",
           "vehicle_type"=>"feet",
           "distance"=>0,
           "start_time"=>nil,
           "end_time"=>nil,
           "organization_name"=>tours.first.user.organization.name,
           "organization_description"=>"Association description",
           "user_id"=>tours.first.user_id,
           "tour_points"=>[]},
          {"id"=>tours.last.id,
           "tour_type"=>"medical",
           "status"=>"ongoing",
           "vehicle_type"=>"feet",
           "distance"=>0,
           "start_time"=>nil,
           "end_time"=>nil,
           "organization_name"=>tours.last.user.organization.name,
           "organization_description"=>"Association description",
           "user_id"=>tours.last.user_id,
           "tour_points"=>[]}]})
    end
     
    context "with limit parameter" do
      before(:each) do
        5.times do |i|
          FactoryGirl.create :tour, updated_at:date+i.days
        end
      end
         
      it "returns status 200" do
        get 'index', token: user.token, limit: 3, :format => :json
        expect(response.status).to eq 200
      end
      
      it "returns last 3 tours" do
        get 'index', token: user.token, limit: 3, :format => :json
        expect(assigns(:tours).count).to eq(3)
        expect(assigns(:tours).all? {|t| t.updated_at >= Date.parse("10/10/2010")+1.days }).to be true
      end
       
    end
     
    context "with type parameter" do 
     
      let!(:tour1) { FactoryGirl.create :tour, tour_type:'medical' }
      let!(:tour2) { FactoryGirl.create :tour, tour_type:'medical' }
      let!(:tour3) { FactoryGirl.create :tour, tour_type:'alimentary' }
      let!(:tour4) { FactoryGirl.create :tour, tour_type:'alimentary' }
      let!(:tour5) { FactoryGirl.create :tour, tour_type:'medical' }
         
      it "returns status 200" do
        get 'index', token: user.token, type:'alimentary', :format => :json
        expect(response.status).to eq 200
      end
      
      it "returns only matching type tours" do
        get 'index', token: user.token, type:'alimentary', :format => :json
        expect(assigns(:tours)).to match_array([tour4, tour3])
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
        expect(assigns(:tours)).to match_array([tour4, tour3])
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
        expect(assigns(:tours)).to match_array([tour4, tour3])
      end
      
      it "returns only matching location tours with provided distance" do
        get 'index', token: user.token, latitude: 10.0, longitude: 10.0, distance: 20.0, :format => :json
        expect(assigns(:tours)).to match_array([tour4, tour3, tour2])
      end
    end
  end
end
