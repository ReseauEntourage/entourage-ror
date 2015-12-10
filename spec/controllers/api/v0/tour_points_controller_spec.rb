require 'rails_helper'

RSpec.describe Api::V0::TourPointsController, :type => :controller do
  render_views

  describe "POST create" do
    let!(:user) { FactoryGirl.create :user }
    let!(:tour) { FactoryGirl.create :tour }
    let!(:length) { 15.38 }
    let!(:tour_point) { FactoryGirl.build :tour_point }
    
    context "within existing tour" do
      before { post 'create', tour_id: tour.id, token: user.token, distance: length, tour_points: [{latitude: tour_point.latitude, longitude: tour_point.longitude, passing_time: tour_point.passing_time}], :format => :json }
      it { should respond_with 201 }
      it { expect(assigns(:tour)).to eq(tour) }
      it { expect((Tour.find tour.id).length).to eq length.to_i }
      it { expect(assigns(:tour).tour_points).to eq([TourPoint.last]) }
    end
    
    context "with multiple tour points" do
      before { post 'create', tour_id: tour.id, token: user.token, distance: length, tour_points: [{latitude: tour_point.latitude, longitude: tour_point.longitude, passing_time: tour_point.passing_time}, {latitude: tour_point.latitude, longitude: tour_point.longitude, passing_time: tour_point.passing_time}], :format => :json }
      it { should respond_with 201 }
      it { expect(assigns(:tour)).to eq(tour) }
      it { expect((Tour.find tour.id).length).to eq length.to_i }
      it { expect(assigns(:tour).tour_points).to eq(TourPoint.last(2)) }
    end

    context "with inexisting tour" do
      before { post 'create', tour_id: 0, token: user.token , tour_points: [{latitude: tour_point.latitude, longitude: tour_point.longitude, passing_time: tour_point.passing_time}], :format => :json }
      it { should respond_with 404 }
    end

    context "with invalid tour_point" do
      before { post 'create', tour_id: tour.id, token: user.token , tour_points: [{latitude: "ABC", longitude: "DEF", passing_time: "GHI"}], :format => :json }
      it { should respond_with 400 }
    end
  end
end
