require 'rails_helper'

describe V1::PoiSerializer do
  include ActiveModel::Serializers
  include ActiveModel::Serializers::JSON

  let(:poi) { create(:poi) }

  let(:serialized) { V1::PoiSerializer.new(poi, scope: { version: :v2 }).serializable_hash }

  describe 'events' do
    it { expect(serialized[:events]).to eq([]) }

    context 'with an upcoming linked event' do
      let(:source) { create(:open_agenda_source) }
      let!(:event) { create(:open_agenda_event, open_agenda_source: source, poi: poi, starts_at: 1.day.from_now) }

      it { expect(serialized[:events].size).to eq(1) }
      it { expect(serialized[:events].first[:id]).to eq(event.id) }
      it { expect(serialized[:events].first[:title]).to eq(event.title) }

      context 'event is in the past' do
        let!(:event) { create(:open_agenda_event, open_agenda_source: source, poi: poi, starts_at: 1.day.ago) }

        it { expect(serialized[:events]).to eq([]) }
      end
    end
  end

  describe 'v1_list version' do
    let(:serialized) { V1::PoiSerializer.new(poi, scope: { version: :v1_list }).serializable_hash }

    it { expect(serialized).not_to have_key(:events) }
  end
end
