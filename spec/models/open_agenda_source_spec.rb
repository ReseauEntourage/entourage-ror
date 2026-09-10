require 'rails_helper'

describe OpenAgendaSource do
  describe 'validations' do
    it { expect(build(:open_agenda_source, name: nil)).not_to be_valid }
    it { expect(build(:open_agenda_source, agenda_uid: nil)).to be_valid }
    it { expect(build(:open_agenda_source, status: 'unknown_status')).not_to be_valid }

    context 'duplicate agenda_uid' do
      let!(:existing) { create(:open_agenda_source, agenda_uid: 82_470_621) }

      it { expect(build(:open_agenda_source, agenda_uid: 82_470_621)).not_to be_valid }
    end

    context 'two sources without agenda_uid' do
      let!(:existing) { create(:open_agenda_source, agenda_uid: nil) }

      it { expect(build(:open_agenda_source, agenda_uid: nil)).to be_valid }
    end
  end

  describe '#mapped?' do
    it { expect(build(:open_agenda_source, partner_id: nil).mapped?).to eq(false) }
    it { expect(build(:open_agenda_source, partner_id: 1).mapped?).to eq(true) }
  end

  describe '#upcoming_events' do
    let(:source) { create(:open_agenda_source) }
    let!(:past_event) { create(:open_agenda_event, open_agenda_source: source, starts_at: 1.day.ago) }
    let!(:future_event) { create(:open_agenda_event, open_agenda_source: source, starts_at: 1.day.from_now) }

    it { expect(source.upcoming_events).to eq([future_event]) }
  end

  describe '#poi_mapped?' do
    it { expect(build(:open_agenda_source, poi_id: nil).poi_mapped?).to eq(false) }
    it { expect(build(:open_agenda_source, poi_id: 1).poi_mapped?).to eq(true) }
  end

  describe 'cascading poi_id to events on update' do
    let(:poi) { create(:poi) }
    let(:source) { create(:open_agenda_source, poi: nil) }
    let!(:event) { create(:open_agenda_event, open_agenda_source: source) }

    it do
      source.update!(poi: poi)
      expect(event.reload.poi_id).to eq(poi.id)
    end
  end
end
