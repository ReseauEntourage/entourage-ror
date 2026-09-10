require 'rails_helper'

describe OpenAgendaEventPoiMatcher do
  subject { OpenAgendaEventPoiMatcher.new(event).match! }

  context 'source has a poi_id set' do
    let(:poi) { create(:poi) }
    let(:source) { create(:open_agenda_source, poi: poi) }
    let(:event) { create(:open_agenda_event, open_agenda_source: source, latitude: nil, longitude: nil) }

    it do
      subject
      expect(event.reload.poi_id).to eq(poi.id)
    end
  end

  context 'source has no poi_id, event has coordinates near a validated poi' do
    let!(:poi) { create(:poi, validated: true, latitude: 48.8566, longitude: 2.3522) }
    let(:source) { create(:open_agenda_source, poi: nil) }
    let(:event) { create(:open_agenda_event, open_agenda_source: source, latitude: 48.8566, longitude: 2.3522) }

    it do
      subject
      expect(event.reload.poi_id).to eq(poi.id)
    end
  end

  context 'nearest poi is outside the match radius' do
    let!(:poi) { create(:poi, validated: true, latitude: 45.7640, longitude: 4.8357) } # Lyon

    let(:source) { create(:open_agenda_source, poi: nil) }
    let(:event) { create(:open_agenda_event, open_agenda_source: source, latitude: 48.8566, longitude: 2.3522) } # Paris

    it do
      subject
      expect(event.reload.poi_id).to be_nil
    end
  end

  context 'nearby poi is not validated' do
    let!(:poi) { create(:poi, validated: false, latitude: 48.8566, longitude: 2.3522) }
    let(:source) { create(:open_agenda_source, poi: nil) }
    let(:event) { create(:open_agenda_event, open_agenda_source: source, latitude: 48.8566, longitude: 2.3522) }

    it do
      subject
      expect(event.reload.poi_id).to be_nil
    end
  end

  context 'event has no coordinates' do
    let(:source) { create(:open_agenda_source, poi: nil) }
    let(:event) { create(:open_agenda_event, open_agenda_source: source, latitude: nil, longitude: nil) }

    it do
      subject
      expect(event.reload.poi_id).to be_nil
    end
  end
end
