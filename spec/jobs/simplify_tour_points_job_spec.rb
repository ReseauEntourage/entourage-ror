require 'rails_helper'

RSpec.describe SimplifyTourPointsJob do
  
  describe 'close!' do
    let!(:tour) { FactoryGirl.create(:tour) }
    let!(:tour_points) { FactoryGirl.create(:tour_point, tour: tour) }
    before { SimplifyTourPointsJob.new.perform(tour.id, false) }
    it { expect($redis.get("entourage:tours:#{tour.id}:tour_points")).to eq("[{\"latitude\":1.5,\"longitude\":1.5}]") }
  end
end