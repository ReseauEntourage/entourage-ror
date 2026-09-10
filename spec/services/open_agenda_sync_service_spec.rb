require 'rails_helper'

describe OpenAgendaSyncService do
  let(:source) { create(:open_agenda_source, agenda_uid: 82_470_621) }

  subject { OpenAgendaSyncService.new(source).sync! }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('OPENAGENDA_PUBLIC_KEY').and_return('oa_pk_test')
  end

  context 'no agenda_uid' do
    let!(:source) { create(:open_agenda_source, agenda_uid: nil) }

    it { expect { subject }.not_to change { OpenAgendaSource.count } }
    it do
      subject
      expect(source.reload.status).to eq('not_checked')
    end
  end

  context 'no public key configured' do
    before { allow(ENV).to receive(:[]).with('OPENAGENDA_PUBLIC_KEY').and_return(nil) }

    it do
      subject
      expect(source.reload.status).to eq('not_exploitable')
      expect(source.last_error).to include('Clé publique')
    end
  end

  context 'valid response' do
    before do
      stub_request(:get, 'https://api.openagenda.com/v2/agendas/82470621/events')
        .with(query: hash_including('key' => 'oa_pk_test'))
        .to_return(status: 200, body: File.read(Rails.root.join('spec/fixtures/open_agenda_events_sample.json')))
    end

    it do
      subject
      expect(source.reload.status).to eq('exploitable')
    end

    it do
      subject
      expect(source.reload.upcoming_events_count).to eq(1)
    end

    it { expect { subject }.to change { OpenAgendaEvent.count }.by(1) }

    it do
      subject
      event = source.reload.open_agenda_events.first
      expect(event.title).to eq('Café des parents')
      expect(event.is_free).to eq(true)
      expect(event.organizer_name).to eq('Bibliothèque municipale de Nantes')
      expect(event.location).to eq('Médiathèque Jacques Demy, 24 quai la Fosse, Nantes')
      expect(event.latitude).to eq(47.2115)
      expect(event.longitude).to eq(-1.5615)
    end

    context 'source already mapped to a poi' do
      let!(:poi) { create(:poi) }
      let(:source) { create(:open_agenda_source, agenda_uid: 82_470_621, poi: poi) }

      it do
        subject
        expect(source.reload.open_agenda_events.first.poi_id).to eq(poi.id)
      end
    end

    context 'a validated poi exists near the event location' do
      let!(:poi) { create(:poi, validated: true, latitude: 47.2115, longitude: -1.5615) }

      it do
        subject
        expect(source.reload.open_agenda_events.first.poi_id).to eq(poi.id)
      end
    end

    context 'API returns the same event uid twice (observed on large aggregator agendas)' do
      before do
        stub_request(:get, 'https://api.openagenda.com/v2/agendas/82470621/events')
          .with(query: hash_including('key' => 'oa_pk_test'))
          .to_return(status: 200, body: {
            total: 2, success: true,
            events: [
              { uid: 4509505, title: { fr: 'Café des parents' }, firstTiming: { begin: '2099-12-31T09:00:00.000+01:00' } },
              { uid: 4509505, title: { fr: 'Café des parents (doublon)' }, firstTiming: { begin: '2099-12-31T09:00:00.000+01:00' } }
            ]
          }.to_json)
      end

      it { expect { subject }.not_to raise_error }
      it { expect { subject }.to change { OpenAgendaEvent.count }.by(1) }
    end

    context 'event removed from a later sync' do
      before do
        subject # first sync, creates the event

        stub_request(:get, 'https://api.openagenda.com/v2/agendas/82470621/events')
          .with(query: hash_including('key' => 'oa_pk_test'))
          .to_return(status: 200, body: '{"total":0,"success":true,"events":[]}')
      end

      it { expect { OpenAgendaSyncService.new(source).sync! }.to change { source.open_agenda_events.count }.from(1).to(0) }
    end
  end

  context 'HTTP error' do
    before do
      stub_request(:get, 'https://api.openagenda.com/v2/agendas/82470621/events')
        .with(query: hash_including('key' => 'oa_pk_test'))
        .to_return(status: 404, body: '{"message":"could not find agenda"}')
    end

    it do
      subject
      expect(source.reload.status).to eq('not_exploitable')
    end
  end

  context 'API returns success: false' do
    before do
      stub_request(:get, 'https://api.openagenda.com/v2/agendas/82470621/events')
        .with(query: hash_including('key' => 'oa_pk_test'))
        .to_return(status: 200, body: '{"success":false,"message":"invalid key"}')
    end

    it do
      subject
      expect(source.reload.status).to eq('not_exploitable')
      expect(source.last_error).to include('invalid key')
    end
  end
end
