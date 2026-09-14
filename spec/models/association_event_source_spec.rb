require 'rails_helper'

describe AssociationEventSource do
  describe 'validations' do
    it { expect(build(:association_event_source, name: nil)).not_to be_valid }
    it { expect(build(:association_event_source, agenda_uid: nil)).to be_valid }
    it { expect(build(:association_event_source, status: 'unknown_status')).not_to be_valid }
    it { expect(build(:association_event_source, provider: 'unknown_provider')).not_to be_valid }

    context 'duplicate agenda_uid' do
      let!(:existing) { create(:association_event_source, agenda_uid: 82_470_621) }

      it { expect(build(:association_event_source, agenda_uid: 82_470_621)).not_to be_valid }
    end

    context 'two sources without agenda_uid' do
      let!(:existing) { create(:association_event_source, agenda_uid: nil) }

      it { expect(build(:association_event_source, agenda_uid: nil)).to be_valid }
    end

    context 'duplicate helloasso_organization_slug' do
      let!(:existing) { create(:association_event_source, :hello_asso, helloasso_organization_slug: 'singa-france') }

      it { expect(build(:association_event_source, :hello_asso, helloasso_organization_slug: 'singa-france')).not_to be_valid }
    end
  end

  describe '#mapped?' do
    it { expect(build(:association_event_source, partner_id: nil).mapped?).to eq(false) }
    it { expect(build(:association_event_source, partner_id: 1).mapped?).to eq(true) }
  end

  describe '#upcoming_events' do
    let(:source) { create(:association_event_source) }
    let!(:past_event) { create(:association_event, association_event_source: source, starts_at: 1.day.ago) }
    let!(:future_event) { create(:association_event, association_event_source: source, starts_at: 1.day.from_now) }

    it { expect(source.upcoming_events).to eq([future_event]) }
  end

  describe '#poi_mapped?' do
    it { expect(build(:association_event_source, poi_id: nil).poi_mapped?).to eq(false) }
    it { expect(build(:association_event_source, poi_id: 1).poi_mapped?).to eq(true) }
  end

  describe '#sync!' do
    it 'dispatches to OpenAgendaSyncService for the open_agenda provider' do
      source = build(:association_event_source)
      expect(OpenAgendaSyncService).to receive(:new).with(source).and_call_original
      source.sync!
    end

    it 'dispatches to HelloAssoSyncService for the hello_asso provider' do
      source = build(:association_event_source, :hello_asso)
      expect(HelloAssoSyncService).to receive(:new).with(source).and_call_original
      source.sync!
    end
  end

  describe 'cascading poi_id to events on update' do
    let(:poi) { create(:poi) }
    let(:source) { create(:association_event_source, poi: nil) }
    let!(:event) { create(:association_event, association_event_source: source) }

    it do
      source.update!(poi: poi)
      expect(event.reload.poi_id).to eq(poi.id)
    end
  end
end
