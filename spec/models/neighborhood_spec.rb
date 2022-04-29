require 'rails_helper'

RSpec.describe Neighborhood, :type => :model do
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:latitude) }
  it { should validate_presence_of(:longitude) }

  describe 'inside_perimeter' do
    let!(:neighborhood) { FactoryBot.create :neighborhood, latitude: 48.86, longitude: 2.35 }
    let(:travel_distance) { 1 }

    # distance is about 26_500 meters
    subject { Neighborhood.inside_perimeter(48.80, 2, travel_distance) }

    context 'travel_distance is too low' do
      it { expect(subject.count).to eq(0) }
    end

    context 'travel_distance is again too low' do
      let(:travel_distance) { 25 }
      it { expect(subject.count).to eq(0) }
    end

    context 'travel_distance is enough' do
      let(:travel_distance) { 28 }
      it { expect(subject.count).to eq(1) }
    end
  end
end
