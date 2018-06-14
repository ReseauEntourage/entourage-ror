require 'rails_helper'

RSpec.describe SimplifyTourPointsJob do
  
  describe 'close!' do
    let!(:tour) { FactoryGirl.create(:tour) }
    before do
      FactoryGirl.create(:tour_point, tour: tour, latitude: "49.40752907", longitude: "0.26782405")
      FactoryGirl.create(:tour_point, tour: tour, latitude: "49.40774009", longitude: "0.26870057")
    end
    before { SimplifyTourPointsJob.new.perform(tour.id, false) }
    it { expect($redis.get("entourage:tours:#{tour.id}:tour_points")).to eq("[{\"latitude\":49.40752907,\"longitude\":0.26782405},{\"latitude\":49.40774009,\"longitude\":0.26870057}]") }
    it { expect(tour.simplified_tour_points.map{|st| {lat: st.latitude, lng: st.longitude} }).to eq([{:lat=>49.40752907, :lng=>0.26782405}, {:lat=>49.40774009, :lng=>0.26870057}]) }
  end
end