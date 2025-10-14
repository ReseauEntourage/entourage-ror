require 'rails_helper'

describe EntourageServices::GeocodingService do
  before do
    EntourageServices::GeocodingService.stub(:enable_callback) { true }
  end

  context 'callbacks' do
    let(:entourage) { build(:entourage) }
    before { allow(EntourageServices::GeocodingService).to receive(:geocode) }
    it 'geocodes on create' do
      entourage.save
      expect(EntourageServices::GeocodingService).to have_received(:geocode).with(entourage.id)
    end

    it 'geocodes on coordinates updates' do
      entourage.save
      expect(EntourageServices::GeocodingService).to receive(:geocode).with(entourage.id)
      entourage.update(latitude: 43)
    end

    it "doesn't geocodes on non-coordinates updates" do
      entourage.save
      expect(EntourageServices::GeocodingService).to_not receive(:geocode)
      entourage.update(status: :closed)
    end
  end

  context 'geocoding' do
    let(:entourage) { build(:entourage, latitude: 48, longitude: 2) }
    before do
      Geocoder.stub(:search).with([48, 2], params: { result_type: :postal_code }) {
        [ OpenStruct.new(types: ['postal_code'], country_code: 'FR', postal_code: '75012', city: 'Paris') ]
      }
    end

    it 'sets the postal code and country code from the API response' do
      entourage.save
      entourage.reload
      expect(entourage.postal_code).to eq '75012'
      expect(entourage.country).to eq 'FR'
      expect(entourage.metadata[:city]).to eq 'Paris'
      expect(entourage.metadata[:display_address]).to eq 'Paris (75012)'
    end
  end
end
