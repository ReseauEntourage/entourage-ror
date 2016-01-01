require 'rails_helper'

RSpec.describe Api::V0::TourPointsController, :type => :controller do
  render_views

  describe "POST create" do
    let!(:user) { FactoryGirl.create :user }
    let!(:tour) { FactoryGirl.create :tour }
    let!(:tour_point) { FactoryGirl.build :tour_point }
    
    context "within existing tour" do
      before { post 'create', tour_id: tour.id, token: user.token, tour_points: [{latitude: tour_point.latitude, longitude: tour_point.longitude, passing_time: tour_point.passing_time}], :format => :json }
      it { expect(response.status).to eq(201) }
      it { expect(JSON.parse(response.body)).to eq({"tour_points"=>[{"latitude"=>1.5, "longitude"=>1.5, "passing_time"=>"12:31"}]}) }
    end
    
    context "with multiple tour points" do
      before { post 'create', tour_id: tour.id, token: user.token, tour_points: [{latitude: tour_point.latitude, longitude: tour_point.longitude, passing_time: tour_point.passing_time}, {latitude: tour_point.latitude, longitude: tour_point.longitude, passing_time: tour_point.passing_time}], :format => :json }
      it { expect(response.status).to eq(201) }
      it { expect(JSON.parse(response.body)).to eq({"tour_points"=>[{"latitude"=>1.5, "longitude"=>1.5, "passing_time"=>"12:31"}, {"latitude"=>1.5, "longitude"=>1.5, "passing_time"=>"12:31"}]}) }
    end

    context "with inexisting tour" do
      it { expect {
            post 'create', tour_id: 0, token: user.token , tour_points: [{latitude: tour_point.latitude, longitude: tour_point.longitude, passing_time: tour_point.passing_time}], :format => :json
          }.to raise_error(ActiveRecord::RecordNotFound)
      }
    end

    context "with invalid tour_point" do
      before { post 'create', tour_id: tour.id, token: user.token , tour_points: [{latitude: "ABC", longitude: "DEF", passing_time: "GHI"}], :format => :json }
      it { expect(response.status).to eq(400) }
    end
  end
end
