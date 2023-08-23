require 'rails_helper'

RSpec.describe Api::V1::TourPointsController, :type => :controller do
  render_views

  describe "POST create" do
    let!(:user) { FactoryBot.create :pro_user }
    let!(:tour) { FactoryBot.create :tour }
    let!(:tour_point) { FactoryBot.build :tour_point }

    context "within existing tour" do
      before { post 'create', params: { tour_id: tour.id, token: user.token, tour_points: [{latitude: tour_point.latitude, longitude: tour_point.longitude, passing_time: tour_point.passing_time.iso8601(3)}], :format => :json } }
      it { expect(response.status).to eq(201) }
      it { expect(JSON.parse(response.body)).to eq({"status"=>"ok"}) }
    end

    context "tour has no location" do
      before { post 'create', params: { tour_id: tour.id, token: user.token, tour_points: [{latitude: tour_point.latitude, longitude: tour_point.longitude, passing_time: tour_point.passing_time.iso8601(3)}], :format => :json } }
      it { expect(tour.reload.longitude).to eq(tour_point.longitude) }
      it { expect(tour.reload.latitude).to eq(tour_point.latitude) }
    end

    context "tour has location" do
      let!(:tour_with_location) { FactoryBot.create(:tour, latitude: 2, longitude: 3) }
      before { post 'create', params: { tour_id: tour_with_location.id, token: user.token, tour_points: [{latitude: tour_point.latitude, longitude: tour_point.longitude, passing_time: tour_point.passing_time.iso8601(3)}], :format => :json } }
      it { expect(tour_with_location.reload.longitude).to eq(3.0) }
      it { expect(tour_with_location.reload.latitude).to eq(2.0) }
    end

    context "with multiple tour points" do
      before { post 'create', params: { tour_id: tour.id, token: user.token, tour_points: [{latitude: tour_point.latitude, longitude: tour_point.longitude, passing_time: tour_point.passing_time.iso8601(3)}, {latitude: tour_point.latitude, longitude: tour_point.longitude, passing_time: tour_point.passing_time.iso8601(3)}], :format => :json } }
      it { expect(response.status).to eq(201) }
      it { expect(JSON.parse(response.body)).to eq({"status"=>"ok"}) }
    end

    context "with inexisting tour" do
      it { expect {
            post 'create', params: { tour_id: 0, token: user.token, tour_points: [{latitude: tour_point.latitude, longitude: tour_point.longitude, passing_time: tour_point.passing_time}], :format => :json }
          }.to raise_error(ActiveRecord::RecordNotFound)
      }
    end

    context "with invalid tour_point" do
      before { post 'create', params: { tour_id: tour.id, token: user.token, tour_points: [{latitude: "ABC", longitude: "DEF", passing_time: "GHI"}], :format => :json } }
      it { expect(response.status).to eq(400) }
    end

    context "with missing passing time" do
      it "raises exception" do
        expect {
          post 'create', params: { tour_id: tour.id, token: user.token, tour_points: {latitude: "ABC", longitude: "DEF"} }
        }.to raise_error(TourPointsServices::MissingPassingTimeError)
      end
    end
  end
end
