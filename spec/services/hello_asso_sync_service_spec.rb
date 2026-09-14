require 'rails_helper'

describe HelloAssoSyncService do
  let(:source) { create(:association_event_source, :hello_asso, helloasso_organization_slug: 'singa-france') }

  subject { HelloAssoSyncService.new(source).sync! }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('HELLOASSO_CLIENT_ID').and_return('client_id_test')
    allow(ENV).to receive(:[]).with('HELLOASSO_CLIENT_SECRET').and_return('client_secret_test')

    stub_request(:post, 'https://api.helloasso.com/oauth2/token')
      .to_return(status: 200, body: { access_token: 'token_test', expires_in: 1800 }.to_json)
  end

  context 'no organization slug' do
    let!(:source) { create(:association_event_source, :hello_asso, helloasso_organization_slug: nil) }

    it { expect { subject }.not_to change { AssociationEventSource.count } }
    it do
      subject
      expect(source.reload.status).to eq('not_checked')
    end
  end

  context 'no credentials configured' do
    before { allow(ENV).to receive(:[]).with('HELLOASSO_CLIENT_ID').and_return(nil) }

    it do
      subject
      expect(source.reload.status).to eq('not_exploitable')
      expect(source.last_error).to include('HELLOASSO_CLIENT_ID')
    end
  end

  context 'valid response' do
    before do
      stub_request(:get, 'https://api.helloasso.com/v5/organizations/singa-france/forms')
        .with(query: hash_including('formTypes' => 'Event', 'states' => 'Public'))
        .to_return(status: 200, body: {
          data: [
            {
              formSlug: 'rencontre-interculturelle',
              title: 'Rencontre interculturelle',
              description: 'Un temps convivial entre réfugiés et habitants',
              startDate: 1.day.from_now.iso8601,
              endDate: (1.day.from_now + 2.hours).iso8601
            }
          ],
          pagination: { continuationToken: nil }
        }.to_json)

      stub_request(:get, 'https://api.helloasso.com/v5/organizations/singa-france/forms/Event/rencontre-interculturelle/public')
        .to_return(status: 200, body: {
          tiers: [{ label: 'Entrée', price: 0 }],
          organizationName: 'SINGA France',
          address: { address: '10 rue de la Paix', zipCode: '75002', city: 'Paris', latitude: 48.8698, longitude: 2.3312 }
        }.to_json)
    end

    it do
      subject
      expect(source.reload.status).to eq('exploitable')
    end

    it { expect { subject }.to change { AssociationEvent.count }.by(1) }

    it do
      subject
      event = source.reload.association_events.first
      expect(event.title).to eq('Rencontre interculturelle')
      expect(event.is_free).to eq(true)
      expect(event.organizer_name).to eq('SINGA France')
      expect(event.location).to eq('10 rue de la Paix, 75002, Paris')
      expect(event.latitude).to eq(48.8698)
      expect(event.provider).to eq('hello_asso')
    end

    context 'a ticket tier has a non-zero price' do
      before do
        stub_request(:get, 'https://api.helloasso.com/v5/organizations/singa-france/forms/Event/rencontre-interculturelle/public')
          .to_return(status: 200, body: { tiers: [{ label: 'Entrée', price: 0 }, { label: 'Soutien', price: 500 }] }.to_json)
      end

      it do
        subject
        expect(source.reload.association_events.first.is_free).to eq(false)
      end
    end

    context 'a tier is "prix libre" (minAmount, no fixed price)' do
      before do
        stub_request(:get, 'https://api.helloasso.com/v5/organizations/singa-france/forms/Event/rencontre-interculturelle/public')
          .to_return(status: 200, body: { tiers: [{ label: 'Prix libre', price: 0, minAmount: 0 }] }.to_json)
      end

      it 'is not treated as strictly free' do
        subject
        expect(source.reload.association_events.first.is_free).to eq(false)
      end
    end

    context 'event removed from a later sync' do
      before do
        subject # first sync, creates the event

        stub_request(:get, 'https://api.helloasso.com/v5/organizations/singa-france/forms')
          .with(query: hash_including('formTypes' => 'Event', 'states' => 'Public'))
          .to_return(status: 200, body: { data: [], pagination: { continuationToken: nil } }.to_json)
      end

      it { expect { HelloAssoSyncService.new(source).sync! }.to change { source.association_events.count }.from(1).to(0) }
    end
  end

  context 'event form is in the past' do
    before do
      stub_request(:get, 'https://api.helloasso.com/v5/organizations/singa-france/forms')
        .with(query: hash_including('formTypes' => 'Event', 'states' => 'Public'))
        .to_return(status: 200, body: {
          data: [{ formSlug: 'vieil-evenement', title: 'Vieil événement', endDate: 1.day.ago.iso8601 }],
          pagination: { continuationToken: nil }
        }.to_json)
    end

    it { expect { subject }.not_to change { AssociationEvent.count } }
  end

  context 'HTTP error while listing forms' do
    before do
      stub_request(:get, 'https://api.helloasso.com/v5/organizations/singa-france/forms')
        .with(query: hash_including('formTypes' => 'Event', 'states' => 'Public'))
        .to_return(status: 404, body: '{"message":"organization not found"}')
    end

    it do
      subject
      expect(source.reload.status).to eq('not_exploitable')
    end
  end

  context 'authentication failure' do
    before do
      stub_request(:post, 'https://api.helloasso.com/oauth2/token')
        .to_return(status: 401, body: '{"error":"invalid_client"}')
    end

    it do
      subject
      expect(source.reload.status).to eq('not_exploitable')
      expect(source.last_error).to include('authentification')
    end
  end
end
