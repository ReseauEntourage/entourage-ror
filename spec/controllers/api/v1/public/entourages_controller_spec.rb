require 'rails_helper'

describe Api::V1::Public::EntouragesController do
  describe 'GET show' do
    let(:entourage) { create :entourage }

    before do
      stub_request(:get,  %r'https://maps.googleapis.com/maps/api/geocode')
        .to_return(status: 200, body: '{}', headers: {})
      get :show, params: { uuid: identifier }
    end

    context 'could get entourage with v1 uuid' do
      let(:identifier) { entourage.uuid.to_param }
      it { expect(response.status).to eq(200) }
      it { expect(JSON.parse(response.body)).to have_key('entourage') }
    end

    context 'could get entourage with v2 uuid' do
      let(:identifier) { entourage.uuid_v2.to_param }
      it { expect(response.status).to eq(200) }
      it { expect(JSON.parse(response.body)).to have_key('entourage') }
    end

    context 'could not get entourage with id' do
      let(:identifier) { entourage.id.to_param }

      it { expect(response.status).to eq(404) }
    end
  end

  describe 'GET index' do
    let(:entourage) { create :entourage }

    before { get :index }
    it { expect(response.status).to eq(200) }
    it { expect(JSON.parse(response.body)).to have_key('entourages') }
  end
end
