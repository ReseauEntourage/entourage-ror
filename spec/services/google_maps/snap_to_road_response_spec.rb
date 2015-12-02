require 'rails_helper'

describe GoogleMap::SnapToRoadResponse do

  context "has JSON" do
    let(:json) { JSON.parse(File.read("spec/fixtures/google_maps/snap_to_road_response.json")) }
    let(:response) { GoogleMap::SnapToRoadResponse.new(json: json) }

    describe 'coordinates_only' do
      it 'should returns all coordinates' do
        expect(response.coordinates_only).to eq([{long: 149.1294692, lat: -35.2784167}, {long: 149.12835061713685, lat: -35.284728724835304}])
      end
    end
  end

  context "nil JSON" do
    let(:response) { GoogleMap::SnapToRoadResponse.new(json: nil) }

    describe 'coordinates_only' do
      it 'should returns all coordinates' do
        expect(response.coordinates_only).to eq([])
      end
    end
  end
end