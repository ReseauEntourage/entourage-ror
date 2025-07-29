require 'rails_helper'

describe UserServices::AddressService do
  let(:paris_google_place_id) { 'paris_google_place_id' }
  let(:nantes_google_place_id) { 'nantes_google_place_id' }
  let(:rennes) { { lat: 48.1, long: -1.7 } }
  let(:lille) { { lat: 50.6, long: 3.06 } }
  let(:nantes) { { lat: 47.22, long: -1.55 } }
  let(:paris) { { lat: 48.9, long: 2.3 } }

  before { GeocodingServices::Finder.stub(:get_geocoder_from_coordinates).with(rennes[:lat], rennes[:long]).and_return(OpenStruct.new(
      postal_code: '35000',
      country_code: 'FR',
      latitude: rennes[:lat],
      longitude: rennes[:long],
      city: 'Rennes',
      data: {
        'formatted_address' => '1 rue Saint Hélier, 35000 Rennes',
        'name' => '1 rue Saint Hélier'
      }
    ))
  }

  before { GeocodingServices::Finder.stub(:get_geocoder_from_coordinates).with(lille[:lat], lille[:long]).and_return(OpenStruct.new(
      postal_code: '59000',
      country_code: 'FR',
      latitude: lille[:lat],
      longitude: lille[:long],
      city: 'Lille',
      data: {
        'formatted_address' => '1 place du Marché, 59000 Lille',
        'name' => '1 place du Marché'
      }
    ))
  }

  before { GeocodingServices::Finder.stub(:get_geocoder_from_place_id).with(nantes_google_place_id).and_return(OpenStruct.new(
      postal_code: '44000',
      country_code: 'FR',
      latitude: nantes[:lat],
      longitude: nantes[:long],
      city: 'Nantes',
      data: {
        'formatted_address' => '1 rue du Commerce, 44000 Nantes',
        'name' => '1 rue du Commerce'
      }
    ))
  }

  before { GeocodingServices::Finder.stub(:get_geocoder_from_place_id).with(paris_google_place_id).and_return(OpenStruct.new(
      postal_code: '75018',
      country_code: 'FR',
      latitude: paris[:lat],
      longitude: paris[:long],
      city: 'Paris',
      data: {
        'formatted_address' => '174 rue Championnet, 44000 Paris',
        'name' => '174 rue Championnet'
      }
    ))
  }

  describe 'update_city_if_nil' do
    let(:address) { FactoryBot.create(:address, google_place_id: google_place_id, latitude: latitude, longitude: longitude) }
    let(:latitude) { 0 }
    let(:longitude) { 0 }

    let(:subject) { UserServices::AddressService.update_city_if_nil(address) }

    before { subject }

    context 'Nantes from google_place_id' do
      let(:google_place_id) { 'nantes_google_place_id' }

      it { expect(address.reload.city).to eq('Nantes') }
    end

    context 'Paris from google_place_id' do
      let(:google_place_id) { 'paris_google_place_id' }

      it { expect(address.reload.city).to eq('Paris') }
    end

    context 'Rennes from google_place_id' do
      let(:google_place_id) { nil }
      let(:latitude) { rennes[:lat] }
      let(:longitude) { rennes[:long] }

      it { expect(address.reload.city).to eq('Rennes') }
    end

    context 'Lille from google_place_id' do
      let(:google_place_id) { nil }
      let(:latitude) { lille[:lat] }
      let(:longitude) { lille[:long] }

      it { expect(address.reload.city).to eq('Lille') }
    end
  end
end
