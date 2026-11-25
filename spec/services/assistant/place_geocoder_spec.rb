require 'rails_helper'

describe Assistant::PlaceGeocoder do
  it 'keeps the text and the answer out of the Sentry breadcrumbs while it geocodes, and only then' do
    seen = []
    allow(Geocoder).to receive(:search) do
      seen << Assistant::Breadcrumbs.suppressed?
      [double(latitude: 45.7, longitude: 4.8, address: 'Lyon', place_id: 'x')]
    end

    described_class.locate('Lyon')

    expect(seen).to eq([true])
    expect(Assistant::Breadcrumbs.suppressed?).to be(false)
  end

  it 'gives the flag back even when the geocoder fails' do
    allow(Geocoder).to receive(:search).and_raise(Geocoder::RequestDenied)

    expect { described_class.locate('Lyon') }.to raise_error(Geocoder::RequestDenied)
    expect(Assistant::Breadcrumbs.suppressed?).to be(false)
  end

  it 'adds no geocoder breadcrumb for a lookup of the assistant, and still adds one for the rest of the app' do
    allow(Sentry).to receive(:add_breadcrumb)
    lookup = Geocoder::Lookup.get(:google)
    allow(lookup).to receive(:_fetch_data).and_return([])
    query = Geocoder::Query.new('Lyon')

    Assistant::Breadcrumbs.suppressed { lookup.send(:fetch_data, query) }
    expect(Sentry).not_to have_received(:add_breadcrumb)

    lookup.send(:fetch_data, query)
    expect(Sentry).to have_received(:add_breadcrumb).twice
  end
end
