require 'rails_helper'

describe Assistant::PlaceGeocoder do
  it 'keeps the text and the answer out of the Sentry breadcrumbs while it geocodes, and only then' do
    seen = []
    allow(Geocoder).to receive(:search) do
      seen << Thread.current[:geocoder_without_breadcrumbs]
      [double(latitude: 45.7, longitude: 4.8, address: 'Lyon', place_id: 'x')]
    end

    described_class.locate('Lyon')

    expect(seen).to eq([true])
    expect(Thread.current[:geocoder_without_breadcrumbs]).to be_nil
  end

  it 'gives the flag back even when the geocoder fails' do
    allow(Geocoder).to receive(:search).and_raise(Geocoder::RequestDenied)

    expect { described_class.locate('Lyon') }.to raise_error(Geocoder::RequestDenied)
    expect(Thread.current[:geocoder_without_breadcrumbs]).to be_nil
  end
end
