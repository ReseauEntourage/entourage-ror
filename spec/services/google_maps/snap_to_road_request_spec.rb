require 'rails_helper'

describe GoogleMap::SnapToRoadRequest do

  let(:request) { GoogleMap::SnapToRoadRequest.new }
  let(:coordinates) { [{long: 149.12958, lat: -35.27801}, {long: 149.12907, lat: -35.28032}] }

  describe "perform" do
    it "returns a SnapToRoadResponse" do
      expect(request.perform(coordinates: coordinates)).to be_a(GoogleMap::SnapToRoadResponse)
    end
  end
  
  describe 'build url' do
    it 'builds an url with coordinates' do
      res = request.build_url(coordinates: coordinates)
      expect(res).to eq("https://roads.googleapis.com/v1/snapToRoads?key=foobar&interpolate=true&path=-35.27801,149.12958|-35.28032,149.12907")
    end
  end

  describe 'snap_points' do
    before(:each) do
      Rails.env.stub(:test?) { false }
    end

    let(:url) { "https://roads.googleapis.com/v1/snapToRoads?key=foobar&interpolate=true&path=-35.27801,149.12958|-35.28032,149.12907" }

    context "valid params" do
      before(:each) do
        stub_request(:get, "https://roads.googleapis.com/v1/snapToRoads?interpolate=true&key=foobar&path=-35.27801,149.12958%7C-35.28032,149.12907").
            to_return(:status => 200, :body => {"snappedPoints" => []}.to_json, :headers => {})
      end

      it "returns the JSON response" do
        expect(request.snap_points(url: url)).to eq({"snappedPoints" => []})
      end
    end

    context "params are invalid" do
      before(:each) do
        stub_request(:get, "https://roads.googleapis.com/v1/snapToRoads?interpolate=true&key=foobar&path=-35.27801,149.12958%7C-35.28032,149.12907").
            to_return(:status => 403, :body => "", :headers => {})
      end

      it "raises an error" do
        expect {request.snap_points(url: url)}.to raise_error(GoogleMap::SnapToRoadRequestError)
      end
    end
  end
end