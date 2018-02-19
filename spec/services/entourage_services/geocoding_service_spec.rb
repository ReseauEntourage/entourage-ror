require 'rails_helper'

describe EntourageServices::GeocodingService do
  before do
    EntourageServices::GeocodingService.stub(:enable_callback) { true }
  end

  context "callbacks" do
    let(:entourage) { build(:entourage) }
    before { allow(EntourageServices::GeocodingService).to receive(:geocode) }
    it "geocodes on create" do
      entourage.save
      expect(EntourageServices::GeocodingService)
        .to have_received(:geocode).with(entourage)
    end

    it "geocodes on coordinates updates" do
      entourage.save
      expect(EntourageServices::GeocodingService)
        .to receive(:geocode)
        .with(entourage)
      entourage.update(latitude: 43)
    end

    it "doesn't geocodes on non-coordinates updates" do
      entourage.save
      expect(EntourageServices::GeocodingService)
        .to_not receive(:geocode)
      entourage.update(status: :closed)
    end
  end

  context "geocoding" do
    let(:entourage) { build(:entourage, latitude: 48.839563, longitude: 2.395748) }
    before do
      stub_request(:get, "https://maps.googleapis.com/maps/api/geocode/json?language=fr&latlng=#{entourage.latitude},#{entourage.longitude}&result_type=postal_code&sensor=false")
        .to_return(status: 200, body: JSON.fast_generate("results"=>[{
          "address_components"=>[
            {"long_name"=>"75012", "short_name"=>"75012", "types"=>["postal_code"]},
            {"long_name"=>"France", "short_name"=>"FR", "types"=>["country"]}
          ],
          "types"=>["postal_code"]
        }], "status"=>"OK"))
    end

    it "sets the postal code and country code from the API response" do
      entourage.save
      entourage.reload
      expect(entourage.postal_code).to eq '75012'
      expect(entourage.country).to eq 'FR'
    end
  end
end
