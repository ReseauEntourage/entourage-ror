require 'rails_helper'

describe PoiServices::SoliguideIndex do
  describe 'post' do
    subject { PoiServices::SoliguideIndex.post params }

    before {
      stub_request(:post, "https://api.soliguide.fr/new-search").to_return(status: 200, body: body, headers: {})
    }

    context 'no response' do
      let(:body) { nil }
      let(:params) { {} }

      it { expect(subject).to eq([]) }
    end

    context 'empty response' do
      let(:body) { "{}" }
      let(:params) { {} }

      it { expect(subject).to eq([]) }
    end

    context 'standard response' do
      let(:body) { ActiveSupport::JSON.encode({
        places: [{
          lieu_id: 1,
          name: 'Entourage',
          entity: { name: 'Entourage', phone: '0102030405' },
          position: {
            location: { coordinates: [ 2.1, 48.2] },
            address: '174 rue Championnet 75018 Paris',
            postalCode: "75018"
          },
        }]
      }) }
      let(:params) { {} }

      it { expect(subject).to eq(
        [{
          uuid: "s1",
          source_id: 1,
          name: "Entourage",
          longitude: 2.1,
          latitude: 48.2,
          address: "174 rue Championnet 75018 Paris",
          postal_code: "75018",
          phone: "0102030405",
          category_id: 0,
          partner_id: nil
        }]
      ) }
    end
  end
end
