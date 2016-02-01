require 'rails_helper'
require 'timecop'

RSpec.describe Tour, :type => :model do
  it { should validate_inclusion_of(:tour_type).in_array(%w(medical barehands alimentary)) }
  it { should define_enum_for(:vehicle_type) }
  it { should define_enum_for(:status) }
  it { should validate_presence_of(:tour_type) }
  it { should validate_presence_of(:vehicle_type) }
  it { should validate_presence_of(:status) }
  it { should validate_presence_of(:user) }
  it { should belong_to(:user) }
  it { should have_many(:tour_points).dependent(:delete_all) }
  it { should have_many(:snap_to_road_tour_points).dependent(:delete_all) }

  it "has many members" do
    user = FactoryGirl.create(:pro_user)
    tour = FactoryGirl.create(:tour)
    ToursUser.create(user: user, tour: tour)
    expect(tour.members).to eq([user])
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
  
  describe '#static_path_map' do
    context 'filled tour' do
      let!(:tour) { create :tour }
      let!(:tour_point1) { create :tour_point, tour: tour, latitude: rand, longitude: rand }
      let!(:tour_point2) { create :tour_point, tour: tour, latitude: rand, longitude: rand }
      let!(:encounter1) { create :encounter, tour: tour, latitude: rand, longitude: rand }
      let!(:encounter2) { create :encounter, tour: tour, latitude: rand, longitude: rand }
      subject { tour.static_path_map }
      it { should be_a GoogleStaticMap }
      it { expect(subject.api_key).to eq "foobar" }
      it { expect(subject.width).to eq 300 }
      it { expect(subject.height).to eq 300 }
      it { expect(subject.paths.length).to eq 1 }
      it { expect(subject.paths[0]).to be_a MapPolygon }
      it { expect(subject.paths[0].color).to eq '0x0000ff' }
      it { expect(subject.paths[0].weight).to eq 5 }
      it { expect(subject.paths[0].polyline).to be true }
      it { expect(subject.paths[0].points.length).to eq 2 }
      it { expect(subject.paths[0].points[0]).to be_a MapLocation }
      it { expect(subject.paths[0].points[0].latitude).to eq tour_point1.latitude.round(4).to_s }
      it { expect(subject.paths[0].points[0].longitude).to eq tour_point1.longitude.round(4).to_s }
      it { expect(subject.paths[0].points[1]).to be_a MapLocation }
      it { expect(subject.paths[0].points[1].latitude).to eq tour_point2.latitude.round(4).to_s }
      it { expect(subject.paths[0].points[1].longitude).to eq tour_point2.longitude.round(4).to_s }
      it { expect(subject.markers.length).to eq 2 }
      it { expect(subject.markers[0]).to be_a MapMarker }
      it { expect(subject.markers[0].label).to eq 'D' }
      it { expect(subject.markers[0].color).to eq 'green' }
      it { expect(subject.markers[0].location).to be_a MapLocation }
      it { expect(subject.markers[0].location.latitude).to eq tour_point1.latitude.round(4).to_s }
      it { expect(subject.markers[0].location.longitude).to eq tour_point1.longitude.round(4).to_s }
      it { expect(subject.markers[1]).to be_a MapMarker }
      it { expect(subject.markers[1].label).to eq 'A' }
      it { expect(subject.markers[1].color).to eq 'red' }
      it { expect(subject.markers[1].location).to be_a MapLocation }
      it { expect(subject.markers[1].location.latitude).to eq tour_point2.latitude.round(4).to_s }
      it { expect(subject.markers[1].location.longitude).to eq tour_point2.longitude.round(4).to_s }
    end
    context 'huge tour' do
      let!(:tour) { create :tour, :filled, point_count: 67, encounter_count: 15 }
      subject { tour.static_path_map point_limit: 30 }

      it { expect(subject.paths[0].points.length).to eq 2 }
      it { expect(subject.paths[0].points[0].latitude).to eq tour.tour_points[0].latitude.round(4).to_s }
      it { expect(subject.paths[0].points[0].longitude).to eq tour.tour_points[0].longitude.round(4).to_s }
      it { expect(subject.paths[0].points[1].latitude).to eq tour.tour_points[1].latitude.round(4).to_s }
      it { expect(subject.paths[0].points[1].longitude).to eq tour.tour_points[1].longitude.round(4).to_s }
    end
    context 'empty tour' do
      let!(:tour) { create :tour }
      subject { tour.static_path_map.url }
      it { should eq '' }
    end
  end
  
  describe 'static_encounters_map' do
    context 'filled tour' do
      let!(:tour) { create :tour }
      let!(:tour_point1) { create :tour_point, tour: tour, latitude: rand, longitude: rand }
      let!(:tour_point2) { create :tour_point, tour: tour, latitude: rand, longitude: rand }
      let!(:encounter1) { create :encounter, tour: tour, latitude: rand, longitude: rand }
      let!(:encounter2) { create :encounter, tour: tour, latitude: rand, longitude: rand }
      subject { tour.static_encounters_map }
      it { should be_a GoogleStaticMap }
      it { expect(subject.api_key).to eq "foobar" }
      it { expect(subject.width).to eq 300 }
      it { expect(subject.height).to eq 300 }
      it { expect(subject.paths.length).to eq 0 }
      it { expect(subject.markers.length).to eq 2 }
      it { expect(subject.markers[0]).to be_a MapMarker }
      it { expect(subject.markers[0].label).to eq '1' }
      it { expect(subject.markers[0].color).to eq 'blue' }
      it { expect(subject.markers[0].location).to be_a MapLocation }
      it { expect(subject.markers[0].location.latitude).to eq encounter1.latitude.round(4).to_s }
      it { expect(subject.markers[0].location.longitude).to eq encounter1.longitude.round(4).to_s }
      it { expect(subject.markers[1]).to be_a MapMarker }
      it { expect(subject.markers[1].label).to eq '2' }
      it { expect(subject.markers[1].color).to eq 'blue' }
      it { expect(subject.markers[1].location).to be_a MapLocation }
      it { expect(subject.markers[1].location.latitude).to eq encounter2.latitude.round(4).to_s }
      it { expect(subject.markers[1].location.longitude).to eq encounter2.longitude.round(4).to_s }
    end
    context 'huge tour' do
      let!(:tour) { create :tour, :filled, point_count: 67, encounter_count: 15 }
      subject { tour.static_encounters_map encounter_limit: 12 }
      it { expect(subject.markers.count).to eq 2 }
      it { expect(subject.markers[0].label).to eq '1' }
      it { expect(subject.markers[1].label).to eq '2' }
    end
    context 'empty tour' do
      let!(:tour) { create :tour }
      subject { tour.static_encounters_map.url }
      it { should eq '' }
    end
  end
  
  describe '#force_close' do
    context 'ongoing tour' do
      let!(:tour) { create :tour, status:'ongoing' }
      before { tour.force_close }
      it { expect(tour.status).to eq 'closed' }
    end
    context 'ongoing tour with tour points' do
      let!(:tour) { create :tour, status:'ongoing' }
      let!(:tour_point1) { create :tour_point, tour: tour, passing_time: (Time.now - 5.hours) }
      let!(:tour_point2) { create :tour_point, tour: tour, passing_time: (Time.now - 4.hours) }
      before { tour.force_close }
      it { expect(tour.status).to eq 'closed' }
      it { expect(tour.closed_at).to eq TourPoint.find(tour_point2.id).passing_time }
    end
  end

  describe "#closed?" do
    let(:open_tour) { FactoryGirl.build(:tour, status: :ongoing) }
    let(:closed_tour) { FactoryGirl.build(:tour, status: :closed) }
    it { expect(open_tour.closed?).to be false }
    it { expect(closed_tour.closed?).to be true }
  end
end
