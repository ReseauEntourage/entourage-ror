require 'rails_helper'

describe TourServices::TourSimplifier do

  describe 'simplified_points' do
    let!(:tour) { FactoryGirl.create(:tour) }
    let(:simplifier) { TourServices::TourSimplifier.new(tour: tour) }

    context "less than 10 points" do
      let!(:tour_points) { FactoryGirl.create(:tour_point, tour: tour) }
      it { expect(simplifier.simplified_points).to eq([tour_points]) }
    end
  end
end
