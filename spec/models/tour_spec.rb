require 'rails_helper'
require 'timecop'

RSpec.describe Tour, :type => :model do
  it { should validate_inclusion_of(:tour_type).in_array(%w(health friendly social food other)) }
  it { should define_enum_for(:vehicle_type) }
  it { should define_enum_for(:status) }
  it { should validate_presence_of(:tour_type) }
  it { should validate_presence_of(:vehicle_type) }
  it { should validate_presence_of(:status) }
  it { should validate_presence_of(:user) }
  it { should belong_to(:user) }
  
  describe '#status=' do
    let!(:time) { DateTime.new 2015, 8, 25, 13, 11, 0 }
    before { Timecop.freeze(time) }
    after { Timecop.return }
    context 'closing' do
      let!(:tour) { Tour.new status: :ongoing, closed_at:nil }
      before { tour.status = 'closed' }
      it { expect(tour.closed_at).to eq time }
      it { expect(tour.status).to eq 'closed' }
    end
    context 'closing again' do
      let!(:other_time) { DateTime.new 2014, 8, 25, 13, 11, 0 }
      let!(:tour) { Tour.new status: :closed, closed_at: other_time }
      before { tour.status = 'closed' }
      it { expect(tour.closed_at).to eq other_time }
      it { expect(tour.status).to eq 'closed' }
    end
    context 'keeping ongoing' do
      let!(:tour) { Tour.new status: :ongoing, closed_at: nil }
      before { tour.status = 'ongoing' }
      it { expect(tour.closed_at).to be nil }
      it { expect(tour.status).to eq 'ongoing' }
    end
  end
  
  describe '#duration' do
    let!(:start) { Time.new 2015, 8, 25, 11, 5, 0 }
    let!(:now) { Time.new 2015, 8, 25, 13, 11, 0 }
    before { Timecop.freeze(now) }
    after { Timecop.return }
    context 'ongoing' do
      let!(:tour) { Tour.new created_at: start, closed_at:nil }
      it { expect(tour.duration).to eq(now - start) }
    end
    context 'closed' do
      let!(:stop) { Time.new 2015, 8, 25, 12, 8, 0 }
      let!(:tour) { Tour.new created_at: start, closed_at:stop }
      it { expect(tour.duration).to eq(stop - start) }
    end
  end
  
  describe '#static_map' do
    context 'filled tour' do
      let!(:tour) { create :tour }
      let!(:tour_point1) { create :tour_point, tour: tour, latitude: rand, longitude: rand }
      let!(:tour_point2) { create :tour_point, tour: tour, latitude: rand, longitude: rand }
      let!(:encounter1) { create :encounter, tour: tour, latitude: rand, longitude: rand }
      let!(:encounter2) { create :encounter, tour: tour, latitude: rand, longitude: rand }
      let!(:static_map) { tour.static_map }
      it { expect(static_map).to be_a GoogleStaticMap }
      it { expect(static_map.width).to eq 512 }
      it { expect(static_map.height).to eq 512 }
      it { expect(static_map.paths.length).to eq 1 }
      it { expect(static_map.paths[0]).to be_a MapPolygon }
      it { expect(static_map.paths[0].color).to eq '0x0000ff' }
      it { expect(static_map.paths[0].weight).to eq 5 }
      it { expect(static_map.paths[0].points.length).to eq 2 }
      it { expect(static_map.paths[0].points[0]).to be_a MapLocation }
      it { expect(static_map.paths[0].points[0].latitude).to eq tour_point1.latitude.to_s }
      it { expect(static_map.paths[0].points[0].longitude).to eq tour_point1.longitude.to_s }
      it { expect(static_map.paths[0].points[1]).to be_a MapLocation }
      it { expect(static_map.paths[0].points[1].latitude).to eq tour_point2.latitude.to_s }
      it { expect(static_map.paths[0].points[1].longitude).to eq tour_point2.longitude.to_s }
      it { expect(static_map.markers.length).to eq 2 }
      it { expect(static_map.markers[0]).to be_a MapMarker }
      it { expect(static_map.markers[0].location).to be_a MapLocation }
      it { expect(static_map.markers[0].location.latitude).to eq encounter1.latitude.to_s }
      it { expect(static_map.markers[0].location.longitude).to eq encounter1.longitude.to_s }
      it { expect(static_map.markers[1]).to be_a MapMarker }
      it { expect(static_map.markers[1].location).to be_a MapLocation }
      it { expect(static_map.markers[1].location.latitude).to eq encounter2.latitude.to_s }
      it { expect(static_map.markers[1].location.longitude).to eq encounter2.longitude.to_s }
    end
    context 'empty tour' do
      let!(:tour) { create :tour }
      let!(:static_map) { tour.static_map }
      it { expect(static_map.url).to eq '' }
    end
  end
end
