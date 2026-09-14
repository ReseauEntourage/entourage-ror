require 'rails_helper'
include AuthHelper

describe Admin::AssociationEventSourcesController do
  render_views

  let!(:user) { admin_basic_login }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('OPENAGENDA_PUBLIC_KEY').and_return('oa_pk_test')
  end

  describe 'GET #index' do
    context 'has sources' do
      let!(:sources) { [create(:association_event_source), create(:association_event_source)] }

      before { get :index }

      it { expect(assigns(:association_event_sources).pluck(:id)).to match_array(sources.pluck(:id)) }
    end

    context 'filtered by status' do
      let!(:exploitable) { create(:association_event_source, status: 'exploitable') }
      let!(:not_checked) { create(:association_event_source, status: 'not_checked') }

      before { get :index, params: { status: 'exploitable' } }

      it { expect(assigns(:association_event_sources).pluck(:id)).to eq([exploitable.id]) }
    end

    context 'filtered by provider' do
      let!(:open_agenda) { create(:association_event_source) }
      let!(:hello_asso) { create(:association_event_source, :hello_asso) }

      before { get :index, params: { provider: 'hello_asso' } }

      it { expect(assigns(:association_event_sources).pluck(:id)).to eq([hello_asso.id]) }
    end

    context 'filtered by mapped' do
      let!(:mapped) { create(:association_event_source, partner: create(:partner)) }
      let!(:unmapped) { create(:association_event_source, partner: nil) }

      before { get :index, params: { mapped: 'yes' } }

      it { expect(assigns(:association_event_sources).pluck(:id)).to eq([mapped.id]) }
    end
  end

  describe 'GET #new' do
    before { get :new }

    it { expect(assigns(:association_event_source)).to be_a_new(AssociationEventSource) }
    it { expect(response.code).to eq('200') }
  end

  describe 'POST #create' do
    context 'open_agenda provider' do
      before do
        stub_request(:get, 'https://api.openagenda.com/v2/agendas/1234/events')
          .with(query: hash_including('key' => 'oa_pk_test'))
          .to_return(status: 404, body: '{"message":"not found"}')
      end

      let(:request) { post :create, params: { association_event_source: { provider: 'open_agenda', name: 'Nouvel agenda', agenda_uid: 1234, city: 'Nantes' } } }

      it { expect { request }.to change { AssociationEventSource.count }.by(1) }

      it 'attempts a sync right away' do
        request
        expect(AssociationEventSource.last.status).to eq('not_exploitable')
      end
    end

    context 'hello_asso provider' do
      before do
        allow(ENV).to receive(:[]).with('HELLOASSO_CLIENT_ID').and_return(nil)
      end

      let(:request) { post :create, params: { association_event_source: { provider: 'hello_asso', name: 'Nouvelle billetterie', helloasso_organization_slug: 'singa-france' } } }

      it { expect { request }.to change { AssociationEventSource.count }.by(1) }

      it 'attempts a sync right away' do
        request
        expect(AssociationEventSource.last.status).to eq('not_exploitable')
        expect(AssociationEventSource.last.last_error).to include('HELLOASSO_CLIENT_ID')
      end
    end
  end

  describe 'GET #show' do
    let!(:source) { create(:association_event_source) }
    let!(:past_event) { create(:association_event, association_event_source: source, starts_at: 1.day.ago) }
    let!(:future_event) { create(:association_event, association_event_source: source, starts_at: 1.day.from_now) }

    before { get :show, params: { id: source.to_param } }

    it { expect(assigns(:association_event_source)).to eq(source) }
    it { expect(assigns(:upcoming_events)).to eq([future_event]) }
  end

  describe 'PUT #update' do
    let!(:source) { create(:association_event_source) }
    let!(:partner) { create(:partner) }

    before do
      put :update, params: { id: source.id, association_event_source: { partner_id: partner.id } }
      source.reload
    end

    it { expect(source.partner_id).to eq(partner.id) }
  end

  describe 'DELETE #destroy' do
    let!(:source) { create(:association_event_source) }

    it { expect { delete :destroy, params: { id: source.id } }.to change { AssociationEventSource.count }.by(-1) }
  end

  describe 'POST #sync' do
    let!(:source) { create(:association_event_source, agenda_uid: 82_470_621) }

    before do
      stub_request(:get, 'https://api.openagenda.com/v2/agendas/82470621/events')
        .with(query: hash_including('key' => 'oa_pk_test'))
        .to_return(status: 200, body: File.read(Rails.root.join('spec/fixtures/open_agenda_events_sample.json')))

      post :sync, params: { id: source.id }
    end

    it { expect(source.reload.status).to eq('exploitable') }
    it { expect(source.reload.upcoming_events_count).to eq(1) }
  end
end
