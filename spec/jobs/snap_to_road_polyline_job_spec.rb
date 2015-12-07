require 'rails_helper'

describe SnapToRoadPolylineJob do
  let(:tour) { FactoryGirl.create(:tour) }
  let(:worker) { SnapToRoadPolylineJob }

  describe 'perform' do
    before(:each) do
      GoogleMap::SnapToRoadResponse.any_instance.stub(:coordinates_only) { [{lat: -35.2784167, long: 149.1294692},
                                                                            {lat: -35.284728724835304, long: 149.12835061713685}] }
      FactoryGirl.create_list(:tour_point, 3, tour: tour)
    end

    it 'should creates snap to road points' do
      expect {
        worker.perform_now(tour.id)
      }.to change {tour.snap_to_road_tour_points.count}.by(2)
    end


    context "large route" do
      before(:each) do
        TourServices::PolylineBuilder.any_instance.stub(:max_point) { 1 }
      end

      it 'concatenates google response' do
        expect {
          worker.perform_now(tour.id)
        }.to change {tour.snap_to_road_tour_points.count}.by(6)
      end
    end
  end
end