require 'rails_helper'

describe TourPointsServices::TourPointsSimplifier do

  let(:tour) { FactoryBot.create(:tour, :filled) }

  describe 'simplified_tour_points' do
    context "valid params" do
      subject { TourPointsServices::TourPointsSimplifier.new(tour_id: tour.id).simplified_tour_points }
      it { expect(subject.flat_map(&:values)).to all(be_a Float) }
    end
  end
end
