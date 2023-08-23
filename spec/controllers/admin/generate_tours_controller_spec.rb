require 'rails_helper'
include AuthHelper

describe Admin::GenerateToursController do

  let!(:user) { admin_basic_login }

  describe 'POST generate' do
    context "missing coordinates" do
      before { post :create }
      it { expect(response.status).to eq(400)}
    end

    context "has coordinates" do
      before { Timecop.freeze(Time.parse("10/10/2010").at_beginning_of_day) }
      subject { post :create, params: { coordinates: [{lat: -35.1, lng: 49.1}, {lat: -35.2, lng: 49.2}] } }

      it { expect { subject }.to change {Tour.count}.by(1) }
      it { expect { subject }.to change {SimplifiedTourPoint.count}.by(2) }

      it "saves tour" do
        subject
        tour = Tour.last
        expect(tour.closed_at.utc).to be_within(1.second).of(Time.parse("10/10/2010").at_beginning_of_day.utc)
        expect(tour.status).to eq("closed")
        expect(tour.vehicle_type).to eq("feet")
        expect(tour.tour_type).to eq("medical")
      end
    end
  end
end
