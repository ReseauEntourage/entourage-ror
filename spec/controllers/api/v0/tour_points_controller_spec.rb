require 'rails_helper'

RSpec.describe Api::V0::TourPointsController, :type => :controller do
  render_views

  describe "POST create" do
    let!(:user) { FactoryGirl.create :pro_user }
    let!(:tour) { FactoryGirl.create :tour }
    let!(:tour_point) { FactoryGirl.build :tour_point }
    
    context "within existing tour" do
      before { post 'create', tour_id: tour.id, token: user.token, tour_points: [{latitude: tour_point.latitude, longitude: tour_point.longitude, passing_time: tour_point.passing_time.iso8601(3)}], :format => :json }
      it { expect(response.status).to eq(201) }
      it { expect(JSON.parse(response.body)).to eq({"status"=>"ok"}) }
    end
    
    context "with multiple tour points" do
      before { post 'create', tour_id: tour.id, token: user.token, tour_points: [{latitude: tour_point.latitude, longitude: tour_point.longitude, passing_time: tour_point.passing_time.iso8601(3)}, {latitude: tour_point.latitude, longitude: tour_point.longitude, passing_time: tour_point.passing_time.iso8601(3)}], :format => :json }
      it { expect(response.status).to eq(201) }
      it { expect(JSON.parse(response.body)).to eq({"status"=>"ok"}) }
    end

    context "with inexisting tour" do
      it { expect {
            post 'create', tour_id: 0, token: user.token , tour_points: [{latitude: tour_point.latitude, longitude: tour_point.longitude, passing_time: tour_point.passing_time.iso8601(3)}], :format => :json
          }.to raise_error(ActiveRecord::RecordNotFound)
      }
    end

    context "with invalid tour_point" do
      before { post 'create', tour_id: tour.id, token: user.token , tour_points: [{latitude: "ABC", longitude: "DEF", passing_time: "GHI"}], :format => :json }
      it { expect(response.status).to eq(400) }
    end
  end
end
